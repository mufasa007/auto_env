import '../../../env_profile/domain/entities/hosts_entry.dart';

/// Encapsulates the `# >>> auto_env managed >>>` ... `# <<< auto_env managed <<<`
/// block inside a hosts file. Lines outside the block are preserved byte-for-byte
/// so other tools (Docker Desktop, Lens, etc.) that touch the same file are
/// not disturbed.
///
/// All operations are pure and platform-agnostic.
abstract final class HostsManagedBlock {
  static const String markerStart = '# >>> auto_env managed >>>';
  static const String markerEnd = '# <<< auto_env managed <<<';

  /// Builds the managed block as a string. `enabled = false` entries are
  /// skipped. The result always ends with [lineEnding].
  static String render(
    List<HostsEntry> entries, {
    String lineEnding = '\n',
  }) {
    final buf = StringBuffer();
    buf.write(markerStart);
    buf.write(lineEnding);
    for (final e in entries) {
      if (!e.enabled) continue;
      buf.write(e.ip);
      buf.write(' ');
      buf.write(e.hostname);
      buf.write(lineEnding);
    }
    buf.write(markerEnd);
    buf.write(lineEnding);
    return buf.toString();
  }

  /// Returns `'\r\n'` if the first line of [content] ends with CRLF, otherwise `'\n'`.
  static String detectLineEnding(String content) {
    final firstLf = content.indexOf('\n');
    if (firstLf > 0 && content[firstLf - 1] == '\r') return '\r\n';
    return '\n';
  }

  /// Splits [hostsRaw] into (before, existingBlock?, after). The three pieces
  /// concatenated equal [hostsRaw] byte-for-byte. `existingBlock` is null when
  /// the markers are absent or only [markerStart] is present without a
  /// matching [markerEnd]. Only the FIRST marker pair is treated as managed;
  /// any subsequent marker pairs are left inside `after` for caller inspection.
  static HostsSplit split(String hostsRaw) {
    final start = _findMarkerLine(hostsRaw, markerStart, from: 0);
    if (start == null) {
      return HostsSplit(before: hostsRaw, existingBlock: null, after: '');
    }
    final end = _findMarkerLine(hostsRaw, markerEnd, from: start.lineEnd);
    if (end == null) {
      return HostsSplit(before: hostsRaw, existingBlock: null, after: '');
    }
    final before = hostsRaw.substring(0, start.lineStart);
    final block = hostsRaw.substring(start.lineStart, end.lineEnd);
    final after = hostsRaw.substring(end.lineEnd);
    return HostsSplit(before: before, existingBlock: block, after: after);
  }

  /// Replaces the existing managed block with [newBlock] (or appends it if
  /// none exists). When appending to a file that does not end with a newline,
  /// a separator is inserted using the dominant line ending of [hostsRaw].
  static String mergeIntoHosts(String hostsRaw, String newBlock) {
    final s = split(hostsRaw);
    if (s.existingBlock == null) {
      if (hostsRaw.isEmpty) return newBlock;
      final needsSeparator = !hostsRaw.endsWith('\n');
      final separator = needsSeparator ? detectLineEnding(hostsRaw) : '';
      return '$hostsRaw$separator$newBlock';
    }
    return '${s.before}$newBlock${s.after}';
  }

  static _LinePos? _findMarkerLine(
    String haystack,
    String marker, {
    required int from,
  }) {
    var idx = from;
    while (idx < haystack.length) {
      final lineStart = idx;
      final newlineIdx = haystack.indexOf('\n', lineStart);
      final lineEnd = newlineIdx < 0 ? haystack.length : newlineIdx + 1;
      var line = haystack.substring(
        lineStart,
        newlineIdx < 0 ? haystack.length : newlineIdx,
      );
      if (line.endsWith('\r')) {
        line = line.substring(0, line.length - 1);
      }
      if (line.trim() == marker) {
        return _LinePos(lineStart, lineEnd);
      }
      idx = lineEnd;
    }
    return null;
  }
}

class HostsSplit {
  const HostsSplit({
    required this.before,
    required this.existingBlock,
    required this.after,
  });

  final String before;
  final String? existingBlock;
  final String after;
}

class _LinePos {
  const _LinePos(this.lineStart, this.lineEnd);
  final int lineStart;
  final int lineEnd;
}
