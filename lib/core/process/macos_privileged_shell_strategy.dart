import 'dart:io';

import 'package:flutter/services.dart';

import '../../features/env_switch/domain/exceptions.dart';
import 'elevation_strategy.dart';

/// Bridges to the Swift `PrivilegedShell` host registered on method channel
/// [_channelName]. Once the user satisfies the Touch ID / password prompt for
/// the first command, every subsequent command in the same app session
/// reuses the cached `AuthorizationRef` with no UI interaction.
///
/// Errors from the Swift side are normalized into our `SwitchException`
/// hierarchy:
///   - `USER_CANCELED` → `PrivilegeDeniedException`
///   - `AUTH_REVOKED`  → `AuthorizationRevokedException`
///   - anything else   → `HostsWriteFailedException` (callers may rewrap)
class MacosPrivilegedShellStrategy implements ElevationStrategy {
  MacosPrivilegedShellStrategy({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'com.autoenv/privileged_shell';

  final MethodChannel _channel;

  /// Calls `ping` on the channel; returns true iff the Swift host is
  /// registered and responds. Used at startup to decide between this strategy
  /// and the osascript fallback.
  Future<bool> capabilityCheck() async {
    try {
      final res = await _channel.invokeMethod<bool>('ping');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? stdin,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<String, Object?>(
        'runWithAdmin',
        <String, Object?>{
          'executable': executable,
          'args': arguments,
          // ignore: use_null_aware_elements — key must be a string literal.
          if (stdin != null) 'stdin': stdin,
        },
      );
      final exitCode = (result?['exitCode'] as int?) ?? 0;
      final stdout = (result?['stdout'] as String?) ?? '';
      final stderr = (result?['stderr'] as String?) ?? '';
      return ProcessResult(0, exitCode, stdout, stderr);
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'USER_CANCELED':
          throw const PrivilegeDeniedException(
            'user canceled administrator prompt',
          );
        case 'AUTH_REVOKED':
          throw const AuthorizationRevokedException(
            'macOS authorization session was revoked',
          );
        default:
          throw HostsWriteFailedException(
            'PrivilegedShell failed (${e.code}): ${e.message}',
          );
      }
    }
  }
}
