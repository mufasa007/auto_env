import '../exceptions/text_parse_exception.dart';

/// Row shape matching the editor's typedef. Lives in domain so the codec
/// has no dependency on presentation.
typedef EnvVarRow = ({String key, String value});

/// Bidirectional codec between env-var rows and dotenv-flavored text.
///
/// **Wire format** — `.env` convention:
///   - `KEY=VALUE` per line. KEY trimmed; VALUE kept as-typed (no quote
///     stripping; trailing whitespace preserved so the user's intent is
///     never silently rewritten).
///   - Lines starting with `#` are ignored (genuine comments).
///   - Empty / whitespace-only lines are skipped.
///   - KEY must match `[A-Za-z_][A-Za-z0-9_]*` — standard POSIX env-var
///     identifier rules.
///   - `=` inside VALUE is allowed; only the first `=` is the separator.
///
/// **Round-trip guarantee**: `parse(serialize(rows))` returns the same
/// rows in order.
class EnvVarTextCodec {
  EnvVarTextCodec._();

  static final _keyPattern = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

  static List<EnvVarRow> parse(String raw) {
    final lines = raw.split('\n');
    final out = <EnvVarRow>[];
    for (var i = 0; i < lines.length; i++) {
      final lineNo = i + 1;
      final line = lines[i];
      final stripped = line.trim();
      if (stripped.isEmpty || stripped.startsWith('#')) continue;

      final eq = line.indexOf('=');
      if (eq <= 0) {
        throw EnvVarTextParseException(
          lineNo,
          'expected "KEY=VALUE" — got "$stripped"',
        );
      }
      final key = line.substring(0, eq).trim();
      final value = line.substring(eq + 1);
      if (!_keyPattern.hasMatch(key)) {
        throw EnvVarTextParseException(
          lineNo,
          '"$key" is not a valid env var name '
          '(letters / digits / underscores, must not start with a digit)',
        );
      }
      out.add((key: key, value: value));
    }
    return out;
  }

  static String serialize(List<EnvVarRow> rows) {
    final buf = StringBuffer();
    for (final r in rows) {
      buf
        ..write(r.key)
        ..write('=')
        ..write(r.value)
        ..writeln();
    }
    return buf.toString();
  }
}
