// auto_env_helper — writes the Windows hosts file with administrator privileges.
//
// Two-stage execution model. The Flutter app launches this binary as a regular
// user (asInvoker manifest), so CreateProcess from Dart succeeds. The bootstrap
// stage then re-launches the same executable via ShellExecuteExW(verb="runas"),
// which is the only Win32 path that triggers a UAC consent prompt.
//
//   Stage 1 (bootstrap, argc == 1):
//     - Read JSON payload from stdin.
//     - Stage it to %TEMP%\auto_env_payload_<guid>.json.
//     - ShellExecuteExW(verb="runas") self with "--apply <staged>".
//     - Wait for the elevated child, propagate its exit code.
//     - Map ShellExecuteEx ERROR_CANCELLED to exit 1223 (matches the contract
//       that WindowsHostsWriter expects for UAC-denied).
//     - Delete the staged file on the way out.
//
//   Stage 2 (apply, argc >= 3 && argv[1] == "--apply"):
//     - Read the staged JSON payload file.
//     - Read the existing hosts file as raw bytes.
//     - Splice the managed block (between markerStart / markerEnd lines) with
//       the new block. Lines outside the managed block are preserved
//       byte-for-byte, mirroring lib/features/env_switch/domain/entities/
//       hosts_managed_block.dart.
//     - Write the merged content to a staging file next to the target, then
//       atomically replace via MoveFileExW(REPLACE_EXISTING | WRITE_THROUGH).
//
// Exit codes:
//   0     success
//   1     I/O failure (read, write, rename, non-cancel ShellExecute failure)
//   2     bad arguments / malformed JSON
//   1223  user denied UAC at bootstrap stage (ERROR_CANCELLED)

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <shellapi.h>
#include <rpc.h>

#include <cstdint>
#include <cstdio>
#include <cstring>
#include <string>

namespace {

constexpr int kExitOk = 0;
constexpr int kExitIo = 1;
constexpr int kExitArgs = 2;
constexpr int kExitUacCancelled = 1223;

struct Payload {
  std::string hostsPath;
  std::string managedBlock;
  std::string markerStart;
  std::string markerEnd;
};

std::wstring Utf8ToWide(const std::string& utf8) {
  if (utf8.empty()) return std::wstring();
  int n = MultiByteToWideChar(CP_UTF8, 0, utf8.data(),
                              static_cast<int>(utf8.size()), nullptr, 0);
  if (n <= 0) return std::wstring();
  std::wstring out(static_cast<size_t>(n), L'\0');
  MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()),
                      out.data(), n);
  return out;
}

std::string ReadAllStdin() {
  HANDLE h = GetStdHandle(STD_INPUT_HANDLE);
  std::string out;
  char buf[4096];
  DWORD n = 0;
  while (ReadFile(h, buf, sizeof(buf), &n, nullptr) && n > 0) {
    out.append(buf, n);
  }
  return out;
}

bool ReadFileBytes(const std::wstring& path, std::string& out) {
  HANDLE h = CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr,
                         OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (h == INVALID_HANDLE_VALUE) return false;
  out.clear();
  char buf[4096];
  DWORD n = 0;
  while (ReadFile(h, buf, sizeof(buf), &n, nullptr) && n > 0) {
    out.append(buf, n);
  }
  CloseHandle(h);
  return true;
}

bool WriteFileBytes(const std::wstring& path, const std::string& content) {
  HANDLE h = CreateFileW(path.c_str(), GENERIC_WRITE, 0, nullptr,
                         CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (h == INVALID_HANDLE_VALUE) return false;
  DWORD written = 0;
  BOOL ok = WriteFile(h, content.data(), static_cast<DWORD>(content.size()),
                      &written, nullptr);
  if (ok) FlushFileBuffers(h);
  CloseHandle(h);
  return ok && written == static_cast<DWORD>(content.size());
}

class JsonReader {
 public:
  explicit JsonReader(const std::string& s) : s_(s) {}

  bool ParseObject(Payload& p) {
    SkipWs();
    if (!Expect('{')) return false;
    bool first = true;
    while (true) {
      SkipWs();
      if (Peek() == '}') {
        ++i_;
        return Validate(p);
      }
      if (!first && !Expect(',')) return false;
      first = false;
      std::string key;
      if (!ParseString(key)) return false;
      if (!Expect(':')) return false;
      std::string val;
      if (!ParseString(val)) return false;
      if (key == "hostsPath") {
        p.hostsPath = val;
      } else if (key == "managedBlock") {
        p.managedBlock = val;
      } else if (key == "markerStart") {
        p.markerStart = val;
      } else if (key == "markerEnd") {
        p.markerEnd = val;
      }
    }
  }

 private:
  const std::string& s_;
  size_t i_ = 0;

  char Peek() const { return i_ < s_.size() ? s_[i_] : '\0'; }

  void SkipWs() {
    while (i_ < s_.size()) {
      char c = s_[i_];
      if (c == ' ' || c == '\t' || c == '\r' || c == '\n') {
        ++i_;
      } else {
        break;
      }
    }
  }

  bool Expect(char c) {
    SkipWs();
    if (i_ >= s_.size() || s_[i_] != c) return false;
    ++i_;
    return true;
  }

  bool ParseString(std::string& out) {
    SkipWs();
    if (Peek() != '"') return false;
    ++i_;
    out.clear();
    while (i_ < s_.size()) {
      char c = s_[i_];
      if (c == '"') {
        ++i_;
        return true;
      }
      if (c != '\\') {
        out.push_back(c);
        ++i_;
        continue;
      }
      if (i_ + 1 >= s_.size()) return false;
      char esc = s_[i_ + 1];
      switch (esc) {
        case '"':  out.push_back('"');  i_ += 2; break;
        case '\\': out.push_back('\\'); i_ += 2; break;
        case '/':  out.push_back('/');  i_ += 2; break;
        case 'n':  out.push_back('\n'); i_ += 2; break;
        case 'r':  out.push_back('\r'); i_ += 2; break;
        case 't':  out.push_back('\t'); i_ += 2; break;
        case 'b':  out.push_back('\b'); i_ += 2; break;
        case 'f':  out.push_back('\f'); i_ += 2; break;
        case 'u': {
          if (i_ + 5 >= s_.size()) return false;
          unsigned code = 0;
          for (int k = 0; k < 4; ++k) {
            char hc = s_[i_ + 2 + k];
            unsigned d;
            if (hc >= '0' && hc <= '9') {
              d = static_cast<unsigned>(hc - '0');
            } else if (hc >= 'a' && hc <= 'f') {
              d = static_cast<unsigned>(hc - 'a' + 10);
            } else if (hc >= 'A' && hc <= 'F') {
              d = static_cast<unsigned>(hc - 'A' + 10);
            } else {
              return false;
            }
            code = (code << 4) | d;
          }
          if (code < 0x80) {
            out.push_back(static_cast<char>(code));
          } else if (code < 0x800) {
            out.push_back(static_cast<char>(0xC0 | (code >> 6)));
            out.push_back(static_cast<char>(0x80 | (code & 0x3F)));
          } else {
            out.push_back(static_cast<char>(0xE0 | (code >> 12)));
            out.push_back(static_cast<char>(0x80 | ((code >> 6) & 0x3F)));
            out.push_back(static_cast<char>(0x80 | (code & 0x3F)));
          }
          i_ += 6;
          break;
        }
        default:
          return false;
      }
    }
    return false;
  }

  static bool Validate(const Payload& p) {
    return !p.hostsPath.empty() && !p.markerStart.empty() &&
           !p.markerEnd.empty();
  }
};

struct LinePos {
  size_t start;
  size_t end;
  bool found;
};

LinePos FindMarkerLine(const std::string& hay, const std::string& marker,
                       size_t from) {
  size_t idx = from;
  while (idx < hay.size()) {
    size_t lineStart = idx;
    size_t nl = hay.find('\n', lineStart);
    size_t lineEnd = (nl == std::string::npos) ? hay.size() : nl + 1;
    size_t contentEnd = (nl == std::string::npos) ? hay.size() : nl;
    if (contentEnd > lineStart && hay[contentEnd - 1] == '\r') --contentEnd;
    size_t l = lineStart;
    size_t r = contentEnd;
    while (l < r && (hay[l] == ' ' || hay[l] == '\t')) ++l;
    while (r > l && (hay[r - 1] == ' ' || hay[r - 1] == '\t')) --r;
    if (r - l == marker.size() &&
        std::memcmp(hay.data() + l, marker.data(), marker.size()) == 0) {
      return {lineStart, lineEnd, true};
    }
    idx = lineEnd;
  }
  return {0, 0, false};
}

std::string DetectLineEnding(const std::string& s) {
  size_t lf = s.find('\n');
  if (lf != std::string::npos && lf > 0 && s[lf - 1] == '\r') return "\r\n";
  return "\n";
}

std::string MergeManagedBlock(const std::string& existing,
                              const std::string& newBlock,
                              const std::string& markerStart,
                              const std::string& markerEnd) {
  LinePos start = FindMarkerLine(existing, markerStart, 0);
  if (!start.found) {
    if (existing.empty()) return newBlock;
    bool needsSep = existing.back() != '\n';
    std::string sep = needsSep ? DetectLineEnding(existing) : std::string();
    return existing + sep + newBlock;
  }
  LinePos end = FindMarkerLine(existing, markerEnd, start.end);
  if (!end.found) {
    if (existing.empty()) return newBlock;
    bool needsSep = existing.back() != '\n';
    std::string sep = needsSep ? DetectLineEnding(existing) : std::string();
    return existing + sep + newBlock;
  }
  return existing.substr(0, start.start) + newBlock + existing.substr(end.end);
}

int Apply(const std::wstring& payloadPathW) {
  std::string payloadJson;
  if (!ReadFileBytes(payloadPathW, payloadJson)) {
    std::fprintf(stderr, "auto_env_helper: cannot read payload (%lu)\n",
                 GetLastError());
    return kExitIo;
  }

  Payload p;
  if (!JsonReader(payloadJson).ParseObject(p)) {
    std::fprintf(stderr, "auto_env_helper: malformed payload JSON\n");
    return kExitArgs;
  }

  std::wstring hostsPathW = Utf8ToWide(p.hostsPath);
  if (hostsPathW.empty()) {
    std::fprintf(stderr, "auto_env_helper: empty hostsPath\n");
    return kExitArgs;
  }

  std::string existing;
  HANDLE hHosts =
      CreateFileW(hostsPathW.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr,
                  OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (hHosts != INVALID_HANDLE_VALUE) {
    char buf[4096];
    DWORD n = 0;
    while (ReadFile(hHosts, buf, sizeof(buf), &n, nullptr) && n > 0) {
      existing.append(buf, n);
    }
    CloseHandle(hHosts);
  } else {
    DWORD err = GetLastError();
    if (err != ERROR_FILE_NOT_FOUND && err != ERROR_PATH_NOT_FOUND) {
      std::fprintf(stderr, "auto_env_helper: cannot read hosts (%lu)\n", err);
      return kExitIo;
    }
  }

  std::string merged =
      MergeManagedBlock(existing, p.managedBlock, p.markerStart, p.markerEnd);

  std::wstring stagingPath = hostsPathW + L".auto_env_tmp";
  if (!WriteFileBytes(stagingPath, merged)) {
    std::fprintf(stderr, "auto_env_helper: cannot write staging (%lu)\n",
                 GetLastError());
    DeleteFileW(stagingPath.c_str());
    return kExitIo;
  }

  if (!MoveFileExW(stagingPath.c_str(), hostsPathW.c_str(),
                   MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)) {
    DWORD err = GetLastError();
    std::fprintf(stderr, "auto_env_helper: MoveFileEx failed (%lu)\n", err);
    DeleteFileW(stagingPath.c_str());
    return kExitIo;
  }
  return kExitOk;
}

int Bootstrap() {
  std::string payload = ReadAllStdin();
  if (payload.empty()) {
    std::fprintf(stderr, "auto_env_helper: empty stdin payload\n");
    return kExitArgs;
  }

  wchar_t tempDir[MAX_PATH + 1] = {};
  DWORD td = GetTempPathW(MAX_PATH + 1, tempDir);
  if (td == 0 || td > MAX_PATH) {
    std::fprintf(stderr, "auto_env_helper: GetTempPath failed (%lu)\n",
                 GetLastError());
    return kExitIo;
  }

  UUID uuid;
  if (UuidCreate(&uuid) != RPC_S_OK) {
    std::fprintf(stderr, "auto_env_helper: UuidCreate failed\n");
    return kExitIo;
  }
  RPC_WSTR uuidStr = nullptr;
  if (UuidToStringW(&uuid, &uuidStr) != RPC_S_OK || uuidStr == nullptr) {
    std::fprintf(stderr, "auto_env_helper: UuidToString failed\n");
    return kExitIo;
  }
  std::wstring tmpPath = std::wstring(tempDir) + L"auto_env_payload_" +
                         reinterpret_cast<wchar_t*>(uuidStr) + L".json";
  RpcStringFreeW(&uuidStr);

  if (!WriteFileBytes(tmpPath, payload)) {
    std::fprintf(stderr, "auto_env_helper: write tmp failed (%lu)\n",
                 GetLastError());
    return kExitIo;
  }

  wchar_t selfPath[MAX_PATH + 1] = {};
  if (GetModuleFileNameW(nullptr, selfPath, MAX_PATH + 1) == 0) {
    std::fprintf(stderr, "auto_env_helper: GetModuleFileName failed (%lu)\n",
                 GetLastError());
    DeleteFileW(tmpPath.c_str());
    return kExitIo;
  }

  std::wstring params = L"--apply \"" + tmpPath + L"\"";

  SHELLEXECUTEINFOW sei = {};
  sei.cbSize = sizeof(sei);
  sei.fMask = SEE_MASK_NOCLOSEPROCESS | SEE_MASK_NOASYNC;
  sei.lpVerb = L"runas";
  sei.lpFile = selfPath;
  sei.lpParameters = params.c_str();
  sei.nShow = SW_HIDE;

  if (!ShellExecuteExW(&sei)) {
    DWORD err = GetLastError();
    DeleteFileW(tmpPath.c_str());
    if (err == ERROR_CANCELLED) return kExitUacCancelled;
    std::fprintf(stderr, "auto_env_helper: ShellExecuteEx failed (%lu)\n", err);
    return kExitIo;
  }

  WaitForSingleObject(sei.hProcess, INFINITE);
  DWORD childExit = 0;
  GetExitCodeProcess(sei.hProcess, &childExit);
  CloseHandle(sei.hProcess);

  DeleteFileW(tmpPath.c_str());
  return static_cast<int>(childExit);
}

}  // namespace

int wmain(int argc, wchar_t** argv) {
  if (argc == 1) return Bootstrap();
  if (argc >= 3 && std::wstring(argv[1]) == L"--apply") {
    return Apply(argv[2]);
  }
  std::fprintf(stderr,
               "usage: auto_env_helper                 (stdin: JSON payload)\n"
               "       auto_env_helper --apply <file>  (internal)\n");
  return kExitArgs;
}
