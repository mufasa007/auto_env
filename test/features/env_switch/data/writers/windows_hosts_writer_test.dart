import 'dart:convert';
import 'dart:io';

import 'package:auto_env/core/process/process_runner.dart';
import 'package:auto_env/features/env_switch/data/writers/windows_hosts_writer.dart';
import 'package:auto_env/features/env_switch/domain/exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProcessRunner extends Mock implements ProcessRunner {}

void main() {
  late Directory tempDir;
  late File hostsFile;
  late File helperExe;
  late _MockProcessRunner runner;
  late WindowsHostsWriter writer;

  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('auto_env_win_hosts_');
    hostsFile = File('${tempDir.path}/hosts');
    helperExe = File('${tempDir.path}/auto_env_helper.exe');
    await helperExe.writeAsString(''); // stand-in: existence is what matters
    runner = _MockProcessRunner();
    writer = WindowsHostsWriter(
      hostsFilePath: hostsFile.path,
      helperExePath: helperExe.path,
      processRunner: runner,
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('readExistingManagedBlock', () {
    test('returns null when hosts file does not exist', () async {
      expect(await writer.readExistingManagedBlock(), isNull);
    });

    test('extracts existing managed block', () async {
      await hostsFile.writeAsString('127.0.0.1 localhost\r\n'
          '# >>> auto_env managed >>>\r\n'
          '10.0.0.1 api.local\r\n'
          '# <<< auto_env managed <<<\r\n');
      final block = await writer.readExistingManagedBlock();
      expect(block, contains('10.0.0.1 api.local'));
    });
  });

  group('applyManagedBlock happy path', () {
    test('invokes helper with JSON payload via stdin and flushes DNS',
        () async {
      when(
        () => runner.run(
          helperExe.path,
          any(),
          stdin: any(named: 'stdin'),
        ),
      ).thenAnswer((_) async => ProcessResult(1, 0, '', ''));
      when(() => runner.run('ipconfig', any()))
          .thenAnswer((_) async => ProcessResult(2, 0, '', ''));

      const newBlock = '# >>> auto_env managed >>>\r\n'
          '10.0.0.1 api.local\r\n'
          '# <<< auto_env managed <<<\r\n';
      await writer.applyManagedBlock(newBlock);

      final stdinCaptured = verify(
        () => runner.run(
          helperExe.path,
          any(),
          stdin: captureAny(named: 'stdin'),
        ),
      ).captured.single as String;
      final payload = jsonDecode(stdinCaptured) as Map<String, dynamic>;
      expect(payload['hostsPath'], hostsFile.path);
      expect(payload['managedBlock'], newBlock);
      expect(payload['markerStart'], '# >>> auto_env managed >>>');
      expect(payload['markerEnd'], '# <<< auto_env managed <<<');

      verify(() => runner.run('ipconfig', ['/flushdns'])).called(1);
    });

    test('does not throw when ipconfig flushdns itself fails', () async {
      when(
        () => runner.run(
          helperExe.path,
          any(),
          stdin: any(named: 'stdin'),
        ),
      ).thenAnswer((_) async => ProcessResult(1, 0, '', ''));
      when(() => runner.run('ipconfig', any()))
          .thenThrow(ProcessException('ipconfig', ['/flushdns']));

      await writer.applyManagedBlock('# >>> auto_env managed >>>\r\n'
          '# <<< auto_env managed <<<\r\n');
      // Did not throw.
    });
  });

  group('applyManagedBlock errors', () {
    test('throws PrivilegeDeniedException on UAC cancel (exit 1223)',
        () async {
      when(
        () => runner.run(
          helperExe.path,
          any(),
          stdin: any(named: 'stdin'),
        ),
      ).thenAnswer((_) async => ProcessResult(1, 1223, '', 'cancelled'));

      await expectLater(
        writer.applyManagedBlock('# >>> auto_env managed >>>\r\n'
            '# <<< auto_env managed <<<\r\n'),
        throwsA(isA<PrivilegeDeniedException>()),
      );
    });

    test('throws HostsWriteFailedException on other non-zero exit', () async {
      when(
        () => runner.run(
          helperExe.path,
          any(),
          stdin: any(named: 'stdin'),
        ),
      ).thenAnswer((_) async => ProcessResult(1, 5, 'oops', 'disk full'));

      await expectLater(
        writer.applyManagedBlock('# >>> auto_env managed >>>\r\n'
            '# <<< auto_env managed <<<\r\n'),
        throwsA(isA<HostsWriteFailedException>()),
      );
    });

    test('throws HostsWriteFailedException when helper binary is missing',
        () async {
      await helperExe.delete();

      await expectLater(
        writer.applyManagedBlock('# >>> auto_env managed >>>\r\n'
            '# <<< auto_env managed <<<\r\n'),
        throwsA(isA<HostsWriteFailedException>()),
      );
    });
  });
}
