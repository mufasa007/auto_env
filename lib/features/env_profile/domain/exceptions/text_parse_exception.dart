/// Errors raised by hosts/env text codecs. Carries the offending line
/// number (1-based) so the editor can highlight it inline.
sealed class TextParseException implements Exception {
  const TextParseException(this.lineNumber, this.reason);

  /// 1-based line number in the user's input.
  final int lineNumber;

  /// Short human-readable reason (English; PR5 will localize callers).
  final String reason;

  @override
  String toString() => '$runtimeType(line $lineNumber): $reason';
}

class HostsTextParseException extends TextParseException {
  const HostsTextParseException(super.lineNumber, super.reason);
}

class EnvVarTextParseException extends TextParseException {
  const EnvVarTextParseException(super.lineNumber, super.reason);
}
