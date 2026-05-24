import '../entities/hosts_entry.dart';
import '../exceptions/text_parse_exception.dart';

/// Bidirectional codec between [HostsEntry] lists and `/etc/hosts`-flavored
/// text.
///
/// **Wire format** — standard hosts file:
///   - `IP HOSTNAME [HOSTNAME2 ...]` — one or more hostnames on one IP.
///     Each hostname produces a separate [HostsEntry] with that IP.
///   - `# IP HOSTNAME` — same shape, but disabled. Round-trips
///     `HostsEntry(enabled: false)`. The `#` must be followed by whitespace
///     so genuine comments (`# this is a note`) are not misread as entries.
///   - Lines starting with `#` that do not parse as a disabled entry are
///     silently dropped (treated as user comments).
///   - Empty / whitespace-only lines are skipped.
///
/// **Round-trip guarantee**: `parse(serialize(entries))` returns the same
/// entries (modulo merging of multi-hostname lines into separate entries —
/// `serialize` always emits one IP+hostname per line for clarity).
class HostsTextCodec {
  HostsTextCodec._();

  static List<HostsEntry> parse(String raw) {
    final lines = raw.split('\n');
    final out = <HostsEntry>[];
    for (var i = 0; i < lines.length; i++) {
      final lineNo = i + 1;
      final trimmed = lines[i].trim();
      if (trimmed.isEmpty) continue;

      var working = trimmed;
      var enabled = true;
      if (working.startsWith('#')) {
        // Try parse as disabled entry: `# IP HOSTNAME ...`.
        final afterHash = working.substring(1).trimLeft();
        if (afterHash.isEmpty) continue; // bare `#`
        // Heuristic: if the first token after `#` looks like an IP (contains
        // a dot or colon) then treat as disabled entry; otherwise it's a
        // human-written comment and we skip.
        final firstTok = afterHash.split(RegExp(r'\s+')).first;
        if (!_looksLikeIp(firstTok)) continue;
        working = afterHash;
        enabled = false;
      }

      final tokens = working.split(RegExp(r'\s+'));
      if (tokens.length < 2) {
        throw HostsTextParseException(
          lineNo,
          'expected "IP HOSTNAME" — got "$trimmed"',
        );
      }
      final ip = tokens[0];
      if (!_looksLikeIp(ip)) {
        throw HostsTextParseException(
          lineNo,
          '"$ip" does not look like an IP address',
        );
      }
      for (final hostname in tokens.skip(1)) {
        if (hostname.startsWith('#')) break; // trailing comment
        out.add(HostsEntry(ip: ip, hostname: hostname, enabled: enabled));
      }
    }
    return out;
  }

  static String serialize(List<HostsEntry> entries) {
    final buf = StringBuffer();
    for (final e in entries) {
      if (!e.enabled) buf.write('# ');
      buf
        ..write(e.ip)
        ..write(' ')
        ..write(e.hostname)
        ..writeln();
    }
    return buf.toString();
  }

  /// Cheap IP-shape check (IPv4 dotted or IPv6 colon-ed). We're not
  /// validating semantics; users may legitimately enter invalid IPs and
  /// that's their problem at switch time, not parse time.
  static bool _looksLikeIp(String token) {
    if (token.isEmpty) return false;
    return token.contains('.') || token.contains(':');
  }
}
