import 'dart:io';

import 'package:auto_env/core/process/process_runner.dart';
import 'package:auto_env/features/env_switch/data/writers/windows_env_var_writer.dart';
import 'package:auto_env/features/env_switch/domain/exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProcessRunner extends Mock implements ProcessRunner {}

void main() {
  late _MockProcessRunner runner;
  late WindowsEnvVarWriter writer;

  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    runner = _MockProcessRunner();
    writer = WindowsEnvVarWriter(processRunner: runner);
  });

  test('batches all set/unset operations into a single powershell call',
      () async {
    when(() => runner.run(any(), any()))
        .thenAnswer((_) async => ProcessResult(1, 0, '', ''));

    await writer.apply(
      {'API_URL': 'https://api.example.com', 'DB_HOST': 'localhost'},
      const {'OLD_VAR': 'oldVal'},
    );

    final captured =
        verify(() => runner.run('powershell', captureAny())).captured;
    expect(captured, hasLength(1));
    final args = captured.single as List<String>;
    expect(args, contains('-NoProfile'));
    expect(args, contains('-Command'));
    final script = args.last;
    expect(
      script,
      contains(
        "[Environment]::SetEnvironmentVariable('API_URL','https://api.example.com','User')",
      ),
    );
    expect(
      script,
      contains(
        "[Environment]::SetEnvironmentVariable('DB_HOST','localhost','User')",
      ),
    );
    expect(
      script,
      contains(r"[Environment]::SetEnvironmentVariable('OLD_VAR',$null,'User')"),
    );
  });

  test('escapes single quotes in values by doubling them', () async {
    when(() => runner.run(any(), any()))
        .thenAnswer((_) async => ProcessResult(1, 0, '', ''));

    await writer.apply({"KEY'S": "val'ue"}, const {});

    final args = verify(() => runner.run('powershell', captureAny()))
        .captured
        .single as List<String>;
    expect(
      args.last,
      contains("[Environment]::SetEnvironmentVariable('KEY''S','val''ue','User')"),
    );
  });

  test('does not spawn powershell when nothing changes', () async {
    await writer.apply(const {}, const {});
    verifyNever(() => runner.run('powershell', any()));
  });

  test('throws EnvVarWriteFailedException on non-zero exit', () async {
    when(() => runner.run('powershell', any())).thenAnswer(
      (_) async => ProcessResult(1, 1, '', 'access denied'),
    );

    await expectLater(
      writer.apply({'BAD': 'value'}, const {}),
      throwsA(isA<EnvVarWriteFailedException>()),
    );
  });

  test('keys present in both next and previous are set, not unset', () async {
    when(() => runner.run(any(), any()))
        .thenAnswer((_) async => ProcessResult(1, 0, '', ''));

    await writer.apply(
      {'API_URL': 'new'},
      const {'API_URL': 'old'},
    );

    final args = verify(() => runner.run('powershell', captureAny()))
        .captured
        .single as List<String>;
    final script = args.last;
    expect(
      script,
      contains("[Environment]::SetEnvironmentVariable('API_URL','new','User')"),
    );
    expect(
      script,
      isNot(contains(r"[Environment]::SetEnvironmentVariable('API_URL',$null")),
    );
  });
}
