import 'dart:io';

import 'package:auto_env/core/process/elevation_strategy.dart';
import 'package:auto_env/features/env_switch/data/writers/macos_hosts_writer.dart';
import 'package:auto_env/features/env_switch/domain/exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockElevationStrategy extends Mock implements ElevationStrategy {}

void main() {
  late Directory tempDir;
  late File hostsFile;
  late _MockElevationStrategy elevation;
  late MacosHostsWriter writer;

  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('auto_env_macos_hosts_');
    hostsFile = File('${tempDir.path}/hosts');
    elevation = _MockElevationStrategy();
    writer = MacosHostsWriter(
      hostsFilePath: hostsFile.path,
      elevation: elevation,
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
    test('runs the cp + dns flush script through the elevation strategy',
        () async {
      await hostsFile.writeAsString('127.0.0.1 localhost\n');

      when(() => elevation.run(any(), any())).thenAnswer((invocation) async {
        final args = invocation.positionalArguments[1] as List<String>;
        // The script is `sh -c '<cmd>'`; extract the cp source/dest and run
        // the copy ourselves so the resulting hosts file matches what the
        // real elevated shell would produce.
        final script = args[1];
        final match =
            RegExp(r'cp "([^"]+)" "([^"]+)"').firstMatch(script)!;
        final src = match.group(1)!;
        final dst = match.group(2)!;
        await File(dst).writeAsString(await File(src).readAsString());
        return ProcessResult(1, 0, '', '');
      });

      const newBlock = '# >>> auto_env managed >>>\n'
          '10.0.0.1 api.local\n'
          '# <<< auto_env managed <<<\n';
      await writer.applyManagedBlock(newBlock);

      final captured =
          verify(() => elevation.run(captureAny(), captureAny())).captured;
      expect(captured[0], '/bin/sh');
      final args = captured[1] as List<String>;
      expect(args[0], '-c');
      expect(args[1], contains('dscacheutil -flushcache'));
      expect(args[1], contains('killall -HUP mDNSResponder'));

      final hostsContent = await hostsFile.readAsString();
      expect(hostsContent, '127.0.0.1 localhost\n$newBlock');
    });

    test('cleans up the temp file after success', () async {
      await hostsFile.writeAsString('');
      when(() => elevation.run(any(), any()))
          .thenAnswer((_) async => ProcessResult(1, 0, '', ''));

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
    test('throws PrivilegeDeniedException when stderr signals user cancel',
        () async {
      await hostsFile.writeAsString('');
      when(() => elevation.run(any(), any())).thenAnswer(
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
      when(() => elevation.run(any(), any())).thenAnswer(
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
      when(() => elevation.run(any(), any())).thenAnswer(
        (_) async => ProcessResult(1, 1, '', 'cp: permission denied'),
      );

      await expectLater(
        writer.applyManagedBlock('# >>> auto_env managed >>>\n'
            '# <<< auto_env managed <<<\n'),
        throwsA(isA<HostsWriteFailedException>()),
      );
    });

    test('AuthorizationRevokedException from strategy is rethrown as-is',
        () async {
      await hostsFile.writeAsString('');
      when(() => elevation.run(any(), any())).thenThrow(
        const AuthorizationRevokedException('session revoked'),
      );

      await expectLater(
        writer.applyManagedBlock('# >>> auto_env managed >>>\n'
            '# <<< auto_env managed <<<\n'),
        throwsA(isA<AuthorizationRevokedException>()),
      );
    });
  });
}
