import 'package:auto_env/core/process/macos_privileged_shell_strategy.dart';
import 'package:auto_env/features/env_switch/domain/exceptions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.autoenv/privileged_shell');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('capabilityCheck returns true when the host responds to ping',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'ping');
      return true;
    });

    final strategy = MacosPrivilegedShellStrategy();
    expect(await strategy.capabilityCheck(), isTrue);
  });

  test('capabilityCheck returns false when the host throws', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw MissingPluginException('no PrivilegedShell registered');
    });

    final strategy = MacosPrivilegedShellStrategy();
    expect(await strategy.capabilityCheck(), isFalse);
  });

  test('run forwards executable + args and parses the result map', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'runWithAdmin');
      final args = call.arguments as Map<dynamic, dynamic>;
      expect(args['executable'], 'sh');
      expect(args['args'], ['-c', 'echo hi']);
      return <String, Object?>{
        'exitCode': 0,
        'stdout': 'hi\n',
        'stderr': '',
      };
    });

    final strategy = MacosPrivilegedShellStrategy();
    final result = await strategy.run('sh', const ['-c', 'echo hi']);
    expect(result.exitCode, 0);
    expect(result.stdout, 'hi\n');
    expect(result.stderr, '');
  });

  test('USER_CANCELED PlatformException maps to PrivilegeDeniedException',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(
        code: 'USER_CANCELED',
        message: 'user canceled administrator prompt',
      );
    });

    final strategy = MacosPrivilegedShellStrategy();
    await expectLater(
      strategy.run('sh', const []),
      throwsA(isA<PrivilegeDeniedException>()),
    );
  });

  test('AUTH_REVOKED PlatformException maps to AuthorizationRevokedException',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(
        code: 'AUTH_REVOKED',
        message: 'auth session revoked',
      );
    });

    final strategy = MacosPrivilegedShellStrategy();
    await expectLater(
      strategy.run('sh', const []),
      throwsA(isA<AuthorizationRevokedException>()),
    );
  });

  test('other PlatformException codes map to HostsWriteFailedException',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(
        code: 'EXECUTE_FAILED',
        message: 'osStatus -25300',
      );
    });

    final strategy = MacosPrivilegedShellStrategy();
    await expectLater(
      strategy.run('sh', const []),
      throwsA(isA<HostsWriteFailedException>()),
    );
  });
}
