import Cocoa
import FlutterMacOS
import Security

/// Re-declare the deprecated `AuthorizationExecuteWithPrivileges` so Swift will
/// link against the C symbol. Apple marks it `unavailable in Swift`, but the
/// implementation is still present on macOS 14/15. PRD-level decision: accept
/// the deprecation risk for session-cached Touch ID and keep `OsascriptStrategy`
/// as the documented fallback when this stops working.
@_silgen_name("AuthorizationExecuteWithPrivileges")
private func AuthorizationExecuteWithPrivileges(
  _ authorization: AuthorizationRef,
  _ pathToTool: UnsafePointer<CChar>,
  _ options: AuthorizationFlags,
  _ arguments: UnsafePointer<UnsafeMutablePointer<CChar>?>,
  _ communicationsPipe: UnsafeMutablePointer<UnsafeMutablePointer<FILE>?>?
) -> OSStatus

/// Bridges Flutter to macOS Authorization Services so a single Touch ID /
/// password prompt unlocks all subsequent `do shell script with administrator
/// privileges` style writes for the lifetime of the app process.
///
/// MethodChannel `com.autoenv/privileged_shell` exposes:
///   - `ping`            → `true` (capability probe)
///   - `runWithAdmin`    → `{exitCode: Int, stdout: String, stderr: String}`
///       arguments: `executable: String`, `args: [String]`,
///                  `timeoutSeconds: Int` (currently advisory)
///
/// Errors surface as `FlutterError`:
///   - `USER_CANCELED`     — Touch ID / password dialog dismissed
///   - `AUTH_REVOKED`      — auth ref still invalid after one rebuild attempt
///   - `EXECUTE_FAILED`    — Authorization Services returned an unexpected OSStatus
///   - `INVALID_ARGUMENTS` — missing / wrong-typed method arguments
final class PrivilegedShell {
  static let channelName = "com.autoenv/privileged_shell"

  private var authRef: AuthorizationRef?

  func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: Self.channelName,
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "DEAD", message: "host released", details: nil))
        return
      }
      switch call.method {
      case "ping":
        result(true)
      case "runWithAdmin":
        self.handleRun(call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func dispose() {
    if let ref = authRef {
      AuthorizationFree(ref, [.destroyRights])
      authRef = nil
    }
  }

  // MARK: -

  private func handleRun(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let executable = args["executable"] as? String,
      let rawArgs = args["args"] as? [String]
    else {
      result(FlutterError(
        code: "INVALID_ARGUMENTS",
        message: "runWithAdmin requires {executable: String, args: [String]}",
        details: nil
      ))
      return
    }

    do {
      let outcome = try execute(executable: executable, args: rawArgs, retry: true)
      result([
        "exitCode": outcome.exitCode,
        "stdout": outcome.stdout,
        "stderr": outcome.stderr,
      ])
    } catch let error as PrivilegedShellError {
      result(error.asFlutterError())
    } catch {
      result(FlutterError(
        code: "EXECUTE_FAILED",
        message: error.localizedDescription,
        details: nil
      ))
    }
  }

  private func execute(
    executable: String,
    args: [String],
    retry: Bool
  ) throws -> (exitCode: Int32, stdout: String, stderr: String) {
    let ref = try ensureAuthRef()

    let argvStorage: [UnsafeMutablePointer<CChar>?] =
      args.map { strdup($0) } + [nil]
    defer {
      for ptr in argvStorage where ptr != nil { free(ptr) }
    }

    var pipe: UnsafeMutablePointer<FILE>?

    let status: OSStatus = executable.withCString { executablePtr in
      argvStorage.withUnsafeBufferPointer { buf -> OSStatus in
        AuthorizationExecuteWithPrivileges(
          ref,
          executablePtr,
          [],
          buf.baseAddress!,
          &pipe
        )
      }
    }

    switch status {
    case errAuthorizationSuccess:
      break
    case errAuthorizationCanceled:
      throw PrivilegedShellError.userCanceled
    case errAuthorizationInvalidRef, errAuthorizationExternalizeNotAllowed:
      // ref expired (sleep / long idle). Rebuild once and retry.
      destroyAuthRef()
      guard retry else { throw PrivilegedShellError.authRevoked }
      return try execute(executable: executable, args: args, retry: false)
    default:
      throw PrivilegedShellError.executeFailed(status)
    }

    let stdout: String
    if let p = pipe {
      stdout = readAll(from: p)
      fclose(p)
    } else {
      stdout = ""
    }
    return (exitCode: 0, stdout: stdout, stderr: "")
  }

  private func ensureAuthRef() throws -> AuthorizationRef {
    if let ref = authRef { return ref }

    var newRef: AuthorizationRef?
    let createStatus = AuthorizationCreate(nil, nil, [], &newRef)
    guard createStatus == errAuthorizationSuccess, let ref = newRef else {
      throw PrivilegedShellError.executeFailed(createStatus)
    }

    let rightName = strdup(kAuthorizationRightExecute)!
    defer { free(rightName) }
    var item = AuthorizationItem(
      name: rightName,
      valueLength: 0,
      value: nil,
      flags: 0
    )
    let copyStatus = withUnsafeMutablePointer(to: &item) { itemPtr -> OSStatus in
      var rights = AuthorizationRights(count: 1, items: itemPtr)
      let flags: AuthorizationFlags = [
        .interactionAllowed,
        .preAuthorize,
        .extendRights,
      ]
      return AuthorizationCopyRights(ref, &rights, nil, flags, nil)
    }

    switch copyStatus {
    case errAuthorizationSuccess:
      authRef = ref
      return ref
    case errAuthorizationCanceled:
      AuthorizationFree(ref, [.destroyRights])
      throw PrivilegedShellError.userCanceled
    default:
      AuthorizationFree(ref, [.destroyRights])
      throw PrivilegedShellError.executeFailed(copyStatus)
    }
  }

  private func destroyAuthRef() {
    if let ref = authRef {
      AuthorizationFree(ref, [.destroyRights])
      authRef = nil
    }
  }

  private func readAll(from file: UnsafeMutablePointer<FILE>) -> String {
    var data = Data()
    let bufSize = 4096
    var buf = [UInt8](repeating: 0, count: bufSize)
    while true {
      let n = buf.withUnsafeMutableBufferPointer { ptr -> Int in
        fread(ptr.baseAddress, 1, bufSize, file)
      }
      if n <= 0 { break }
      data.append(buf, count: n)
    }
    return String(data: data, encoding: .utf8) ?? ""
  }
}

private enum PrivilegedShellError: Error {
  case userCanceled
  case authRevoked
  case executeFailed(OSStatus)

  func asFlutterError() -> FlutterError {
    switch self {
    case .userCanceled:
      return FlutterError(
        code: "USER_CANCELED",
        message: "user canceled administrator prompt",
        details: nil
      )
    case .authRevoked:
      return FlutterError(
        code: "AUTH_REVOKED",
        message: "authorization session was revoked",
        details: nil
      )
    case .executeFailed(let status):
      return FlutterError(
        code: "EXECUTE_FAILED",
        message: "AuthorizationExecuteWithPrivileges failed",
        details: ["osStatus": Int(status)]
      )
    }
  }
}
