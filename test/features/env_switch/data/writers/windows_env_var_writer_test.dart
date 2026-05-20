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

  test(
      'writes via direct registry calls and ends with one bounded broadcast',
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

    // Opens HKCU\Environment once for the whole batch — no per-key broadcast.
    expect(
      script,
      contains(
        r"[Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment',$true)",
      ),
    );

    // Sets via direct registry write (REG_SZ for plain values).
    expect(
      script,
      contains(
        r"$key.SetValue('API_URL','https://api.example.com',[Microsoft.Win32.RegistryValueKind]::String)",
      ),
    );
    expect(
      script,
      contains(
        r"$key.SetValue('DB_HOST','localhost',[Microsoft.Win32.RegistryValueKind]::String)",
      ),
    );

    // Unsets via DeleteValue (no exception when missing).
    expect(
      script,
      contains(r"$key.DeleteValue('OLD_VAR',$false)"),
    );

    // The slow per-key API is gone.
    expect(script, isNot(contains('SetEnvironmentVariable')));

    // Exactly one bounded WM_SETTINGCHANGE broadcast at the end.
    // SMTO_ABORTIFHUNG (0x0002) + 1000ms cap is the whole point of this rewrite.
    // (The literal `SendMessageTimeout` also appears in the P/Invoke prototype,
    // so we count the call site `[W.N]::SendMessageTimeout(...)` instead.)
    expect(
      r'[W.N]::SendMessageTimeout('.allMatches(script).length,
      1,
    );
    expect(script, contains("'Environment'"));
    expect(script, contains('0x0002'));
    expect(script, contains('1000'));
  });

  test('writes REG_EXPAND_SZ when the value contains a %', () async {
    when(() => runner.run(any(), any()))
        .thenAnswer((_) async => ProcessResult(1, 0, '', ''));

    await writer.apply({'PATHX': r'%USERPROFILE%\bin'}, const {});

    final args = verify(() => runner.run('powershell', captureAny()))
        .captured
        .single as List<String>;
    expect(
      args.last,
      contains('[Microsoft.Win32.RegistryValueKind]::ExpandString'),
    );
    expect(
      args.last,
      isNot(contains('[Microsoft.Win32.RegistryValueKind]::String)')),
    );
  });

  test('escapes single quotes in keys and values by doubling them', () async {
    when(() => runner.run(any(), any()))
        .thenAnswer((_) async => ProcessResult(1, 0, '', ''));

    await writer.apply({"KEY'S": "val'ue"}, const {});

    final args = verify(() => runner.run('powershell', captureAny()))
        .captured
        .single as List<String>;
    expect(
      args.last,
      contains(
        r"$key.SetValue('KEY''S','val''ue',[Microsoft.Win32.RegistryValueKind]::String)",
      ),
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
      contains(
        r"$key.SetValue('API_URL','new',[Microsoft.Win32.RegistryValueKind]::String)",
      ),
    );
    expect(
      script,
      isNot(contains(r"$key.DeleteValue('API_URL'")),
    );
  });
}
