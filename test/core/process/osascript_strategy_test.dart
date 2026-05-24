import 'dart:io';

import 'package:auto_env/core/process/osascript_strategy.dart';
import 'package:auto_env/core/process/process_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProcessRunner extends Mock implements ProcessRunner {}

void main() {
  late _MockProcessRunner runner;
  late OsascriptStrategy strategy;

  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    runner = _MockProcessRunner();
    strategy = OsascriptStrategy(processRunner: runner);
    when(() => runner.run(any(), any(), stdin: any(named: 'stdin')))
        .thenAnswer((_) async => ProcessResult(1, 0, '', ''));
  });

  test('wraps the command in osascript -e with administrator privileges',
      () async {
    await strategy.run('cp', ['/tmp/a', '/tmp/b']);

    final captured =
        verify(() => runner.run('osascript', captureAny())).captured.single
            as List<String>;
    expect(captured[0], '-e');
    expect(captured[1], contains('do shell script'));
    expect(captured[1], contains('with administrator privileges'));
    expect(captured[1], contains(r'\"cp\"'));
    expect(captured[1], contains(r'\"/tmp/a\"'));
    expect(captured[1], contains(r'\"/tmp/b\"'));
  });

  test('forwards stdin to the underlying process runner', () async {
    await strategy.run('cat', const <String>[], stdin: 'hello');

    verify(
      () => runner.run('osascript', any(), stdin: 'hello'),
    ).called(1);
  });

  test('escapes embedded double quotes and backslashes in arguments',
      () async {
    await strategy.run('sh', ['-c', 'echo "hi" && true']);

    final captured =
        verify(() => runner.run('osascript', captureAny())).captured.single
            as List<String>;
    final script = captured[1];
    expect(script, contains(r'\"-c\"'));
    // Inner double quotes from the user payload survive as backslash-escaped
    // quotes inside the AppleScript string literal.
    expect(script, contains(r'echo \"hi\" && true'));
  });

  test('propagates the underlying process result unchanged', () async {
    when(() => runner.run(any(), any(), stdin: any(named: 'stdin')))
        .thenAnswer((_) async => ProcessResult(42, 1, 'out', 'err'));

    final result = await strategy.run('false', const <String>[]);

    expect(result.exitCode, 1);
    expect(result.stdout, 'out');
    expect(result.stderr, 'err');
    expect(result.pid, 42);
  });
}
