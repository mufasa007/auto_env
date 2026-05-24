import 'package:auto_env/features/env_profile/domain/exceptions/text_parse_exception.dart';
import 'package:auto_env/features/env_profile/domain/services/env_var_text_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnvVarTextCodec.parse', () {
    test('plain KEY=VALUE parses', () {
      final rows = EnvVarTextCodec.parse('API_BASE=https://api.dev\n');
      expect(rows, [(key: 'API_BASE', value: 'https://api.dev')]);
    });

    test('# comments and blank lines are skipped', () {
      final rows = EnvVarTextCodec.parse(
        '# config for dev\n'
        '\n'
        'API_BASE=https://api.dev\n'
        '  \n',
      );
      expect(rows, [(key: 'API_BASE', value: 'https://api.dev')]);
    });

    test('empty value is allowed (KEY=)', () {
      final rows = EnvVarTextCodec.parse('FEATURE_FLAG=\n');
      expect(rows, [(key: 'FEATURE_FLAG', value: '')]);
    });

    test('= inside value is preserved (only first = is separator)', () {
      final rows = EnvVarTextCodec.parse('TOKEN=abc=def=ghi\n');
      expect(rows, [(key: 'TOKEN', value: 'abc=def=ghi')]);
    });

    test('value keeps quotes and trailing whitespace literally', () {
      final rows = EnvVarTextCodec.parse('GREETING="hello "  \n');
      expect(rows, [(key: 'GREETING', value: '"hello "  ')]);
    });

    test('missing = throws with line number', () {
      expect(
        () => EnvVarTextCodec.parse(
          'API=ok\n'
          'BROKEN\n',
        ),
        throwsA(
          isA<EnvVarTextParseException>()
              .having((e) => e.lineNumber, 'lineNumber', 2),
        ),
      );
    });

    test('invalid key (starts with digit) throws', () {
      expect(
        () => EnvVarTextCodec.parse('1API=value\n'),
        throwsA(isA<EnvVarTextParseException>()),
      );
    });

    test('invalid key (hyphen) throws', () {
      expect(
        () => EnvVarTextCodec.parse('MY-VAR=value\n'),
        throwsA(isA<EnvVarTextParseException>()),
      );
    });
  });

  group('EnvVarTextCodec.serialize', () {
    test('KEY=VALUE per row', () {
      final text = EnvVarTextCodec.serialize(const [
        (key: 'A', value: '1'),
        (key: 'LOG_LEVEL', value: 'debug'),
      ]);
      expect(text, 'A=1\nLOG_LEVEL=debug\n');
    });
  });

  group('round-trip', () {
    test('parse(serialize(rows)) == rows', () {
      const rows = [
        (key: 'API_BASE', value: 'https://api.dev'),
        (key: 'FEATURE_FLAG', value: ''),
        (key: 'TOKEN', value: 'abc=def'),
      ];
      final reparsed =
          EnvVarTextCodec.parse(EnvVarTextCodec.serialize(rows));
      expect(reparsed, rows);
    });
  });
}
