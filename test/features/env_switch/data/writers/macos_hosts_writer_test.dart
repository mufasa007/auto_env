import 'dart:io';

import 'package:auto_env/core/process/process_runner.dart';
import 'package:auto_env/features/env_switch/data/writers/macos_hosts_writer.dart';
import 'package:auto_env/features/env_switch/domain/exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProcessRunner extends Mock implements ProcessRunner {}

void main() {
  late Directory tempDir;
  late File hostsFile;
  late _MockProcessRunner runner;
  late MacosHostsWriter writer;

  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('auto_env_macos_hosts_');
    hostsFile = File('${tempDir.path}/hosts');
    runner = _MockProcessRunner();
    writer = MacosHostsWriter(
      hostsFilePath: hostsFile.path,
      processRunner: runner,
      tempDirPath: tempDir.path,
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('readExistingManagedBlock', () {
    test('returns null when hosts file does not exist', () async {
      expect(await writer.readExistingManagedBlock(), isNull);
    });

    test('returns null when hosts has no auto_env markers', () async {
      await hostsFile.writeAsString('127.0.0.1 localhost\n');
      expect(await writer.readExistingManagedBlock(), isNull);
    });

    test('extracts the existing managed block including markers', () async {
      await hostsFile.writeAsString('127.0.0.1 localhost\n'
          '# >>> auto_env managed >>>\n'
          '10.0.0.1 api.local\n'
          '# <<< auto_env managed <<<\n');
      final block = await writer.readExistingManagedBlock();
      expect(block, contains('10.0.0.1 api.local'));
      expect(block, startsWith('# >>> auto_env managed >>>'));
    });
  });

  group('applyManagedBlock happy path', () {
    test('writes merged content via osascript with administrator privileges',
        () async {
      await hostsFile.writeAsString('127.0.0.1 localhost\n');
      when(() => runner.run(any(), any()))
          .thenAnswer((_) async => ProcessResult(1, 0, '', ''));

      const newBlock = '# >>> auto_env managed >>>\n'
          '10.0.0.1 api.local\n'
          '# <<< auto_env managed <<<\n';

      // Capture the staged temp file path used inside the osascript
      // command BEFORE the (mocked) osascript runs. To simulate a real
      // success we intercept the `cp` step by mirroring it ourselves.
      when(() => runner.run('osascript', any())).thenAnswer((invocation) async {
        final args = invocation.positionalArguments[1] as List<String>;
        final script = args[1];
        // Extract source temp path between first pair of \" markers.
        final match = RegExp(r'cp \\"([^\\"]+)\\" \\"([^\\"]+)\\"')
            .firstMatch(script)!;
        final src = match.group(1)!;
        final dst = match.group(2)!;
        await File(dst).writeAsString(await File(src).readAsString());
        return ProcessResult(1, 0, '', '');
      });

      await writer.applyManagedBlock(newBlock);

      final captured = verify(() => runner.run('osascript', captureAny()))
          .captured
          .single as List<String>;
      expect(captured[0], '-e');
      expect(captured[1], contains('with administrator privileges'));
      expect(captured[1], contains('dscacheutil -flushcache'));
      expect(captured[1], contains('killall -HUP mDNSResponder'));

      final hostsContent = await hostsFile.readAsString();
      expect(hostsContent, '127.0.0.1 localhost\n$newBlock');
    });

    test('cleans up the temp file after success', () async {
      await hostsFile.writeAsString('');
      when(() => runner.run(any(), any())).thenAnswer((invocation) async {
        // Simulate cp running but do not bother copying — we only care about
        // tmp cleanup, hosts content is asserted elsewhere.
        return ProcessResult(1, 0, '', '');
      });

      await writer.applyManagedBlock(
        '# >>> auto_env managed >>>\n# <<< auto_env managed <<<\n',
      );

      final remaining = tempDir
          .listSync()
          .where((e) => e.uri.pathSegments.last.startsWith('auto_env_hosts_'))
          .toList();
      expect(remaining, isEmpty);
    });
  });

  group('applyManagedBlock errors', () {
    test('throws PrivilegeDeniedException when user cancels osascript',
        () async {
      await hostsFile.writeAsString('');
      when(() => runner.run(any(), any())).thenAnswer(
        (_) async => ProcessResult(
          1,
          1,
          '',
          'execution error: User canceled. (-128)',
        ),
      );

      await expectLater(
        writer.applyManagedBlock('# >>> auto_env managed >>>\n'
            '# <<< auto_env managed <<<\n'),
        throwsA(isA<PrivilegeDeniedException>()),
      );
    });

    test('throws PrivilegeDeniedException on wrong password (-60005)',
        () async {
      await hostsFile.writeAsString('');
      when(() => runner.run(any(), any())).thenAnswer(
        (_) async => ProcessResult(
          1,
          1,
          '',
          '0:225: execution error: 管理员用户名或密码不正确。(-60005)',
        ),
      );

      await expectLater(
        writer.applyManagedBlock('# >>> auto_env managed >>>\n'
            '# <<< auto_env managed <<<\n'),
        throwsA(isA<PrivilegeDeniedException>()),
      );
    });

    test('throws HostsWriteFailedException on non-cancel failure', () async {
      await hostsFile.writeAsString('');
      when(() => runner.run(any(), any())).thenAnswer(
        (_) async => ProcessResult(1, 1, '', 'cp: permission denied'),
      );

      await expectLater(
        writer.applyManagedBlock('# >>> auto_env managed >>>\n'
            '# <<< auto_env managed <<<\n'),
        throwsA(isA<HostsWriteFailedException>()),
      );
    });
  });
}
