import 'dart:io';

import 'package:auto_env/core/process/process_runner.dart';
import 'package:auto_env/features/env_switch/data/writers/macos_env_var_writer.dart';
import 'package:auto_env/features/env_switch/domain/exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProcessRunner extends Mock implements ProcessRunner {}

void main() {
  late Directory tempDir;
  late File shellFile;
  late _MockProcessRunner runner;
  late MacosEnvVarWriter writer;

  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('auto_env_macos_env_');
    shellFile = File('${tempDir.path}/env.sh');
    runner = _MockProcessRunner();
    writer = MacosEnvVarWriter(
      processRunner: runner,
      shellFile: shellFile,
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('calls launchctl setenv for each new var and writes env.sh', () async {
    when(() => runner.run(any(), any()))
        .thenAnswer((_) async => ProcessResult(1, 0, '', ''));

    await writer.apply(
      {'API_URL': 'https://api.example.com', 'DB_HOST': 'localhost'},
      const {},
    );

    final calls = verify(() => runner.run('launchctl', captureAny()))
        .captured
        .cast<List<String>>();
    expect(calls, hasLength(2));
    expect(
      calls,
      containsAll(<List<String>>[
        ['setenv', 'API_URL', 'https://api.example.com'],
        ['setenv', 'DB_HOST', 'localhost'],
      ]),
    );

    final shellContent = await shellFile.readAsString();
    expect(shellContent, contains('# >>> auto_env env >>>'));
    expect(shellContent, contains('# <<< auto_env env <<<'));
    expect(shellContent, contains('export API_URL="https://api.example.com"'));
    expect(shellContent, contains('export DB_HOST="localhost"'));
  });

  test('unsets keys that were previously applied but not in next', () async {
    when(() => runner.run(any(), any()))
        .thenAnswer((_) async => ProcessResult(1, 0, '', ''));

    await writer.apply(
      {'API_URL': 'new'},
      const {'OLD_VAR': 'someValue', 'API_URL': 'oldValue'},
    );

    final calls = verify(() => runner.run('launchctl', captureAny()))
        .captured
        .cast<List<String>>();
    expect(
      calls,
      containsAll(<List<String>>[
        ['setenv', 'API_URL', 'new'],
        ['unsetenv', 'OLD_VAR'],
      ]),
    );
    // API_URL should NOT be unset because it is in next
    final unsetCalls =
        calls.where((c) => c.first == 'unsetenv').map((c) => c[1]).toList();
    expect(unsetCalls, ['OLD_VAR']);
  });

  test('escapes shell-special characters in env.sh values', () async {
    when(() => runner.run(any(), any()))
        .thenAnswer((_) async => ProcessResult(1, 0, '', ''));

    await writer.apply(
      {'TRICKY': r'a "quote" and $var and `backtick` and \slash'},
      const {},
    );

    final shellContent = await shellFile.readAsString();
    expect(
      shellContent,
      contains(
        r'export TRICKY="a \"quote\" and \$var and \`backtick\` and \\slash"',
      ),
    );
  });

  test('throws EnvVarWriteFailedException when launchctl setenv fails',
      () async {
    when(() => runner.run('launchctl', any())).thenAnswer(
      (_) async => ProcessResult(1, 1, '', 'launchctl: bad arg'),
    );

    await expectLater(
      writer.apply({'BAD': 'value'}, const {}),
      throwsA(isA<EnvVarWriteFailedException>()),
    );
  });

  test('does nothing when next and previous are both empty', () async {
    when(() => runner.run(any(), any()))
        .thenAnswer((_) async => ProcessResult(1, 0, '', ''));

    await writer.apply(const {}, const {});

    verifyNever(() => runner.run('launchctl', any()));
    expect(await shellFile.exists(), isTrue);
    final shellContent = await shellFile.readAsString();
    expect(shellContent, contains('# >>> auto_env env >>>'));
  });
}
