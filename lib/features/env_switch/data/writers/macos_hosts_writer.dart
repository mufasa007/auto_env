import 'dart:io';

import '../../../../core/process/process_runner.dart';
import '../../domain/entities/hosts_managed_block.dart';
import '../../domain/exceptions.dart';
import 'hosts_writer.dart';

/// Writes /etc/hosts on macOS by staging the new content in a temp file and
/// asking osascript to copy it into place with administrator privileges.
/// The same osascript invocation also flushes the DNS cache so the user
/// only sees one Touch ID / password prompt per switch.
class MacosHostsWriter implements HostsWriter {
  MacosHostsWriter({
    required this.hostsFilePath,
    required this.processRunner,
    String? tempDirPath,
  }) : tempDirPath = tempDirPath ?? Directory.systemTemp.path;

  final String hostsFilePath;
  final ProcessRunner processRunner;
  final String tempDirPath;

  @override
  Future<String?> readExistingManagedBlock() async {
    final file = File(hostsFilePath);
    if (!await file.exists()) return null;
    final raw = await file.readAsString();
    return HostsManagedBlock.split(raw).existingBlock;
  }

  @override
  Future<void> applyManagedBlock(String newBlock) async {
    final hostsFile = File(hostsFilePath);
    final raw = await hostsFile.exists() ? await hostsFile.readAsString() : '';
    final merged = HostsManagedBlock.mergeIntoHosts(raw, newBlock);

    final stamp = DateTime.now().microsecondsSinceEpoch;
    final tmpFile = File('$tempDirPath/auto_env_hosts_$stamp');
    await tmpFile.writeAsString(merged, flush: true);

    try {
      final script = 'do shell script "'
          'cp \\"${tmpFile.path}\\" \\"$hostsFilePath\\" && '
          'dscacheutil -flushcache && '
          'killall -HUP mDNSResponder'
          '" with administrator privileges';
      final result = await processRunner.run('osascript', ['-e', script]);
      if (result.exitCode != 0) {
        final stderr = '${result.stderr}';
        if (_isPrivilegeDenial(stderr)) {
          throw PrivilegeDeniedException(_describePrivilegeDenial(stderr));
        }
        throw HostsWriteFailedException(
          'osascript exit ${result.exitCode}: $stderr',
        );
      }
    } finally {
      if (await tmpFile.exists()) {
        try {
          await tmpFile.delete();
        } catch (_) {
          // best effort cleanup
        }
      }
    }
  }

  /// osascript surfaces the underlying OSStatus code in stderr. We treat any
  /// code in the Security framework's authorization family as a privilege
  /// denial so the UI can offer Retry instead of a generic write-failed error.
  ///
  /// `-128` = user canceled the prompt.
  /// `-60005` = errAuthorizationFailed (wrong administrator password).
  /// `-60006` = errAuthorizationDenied (user not authorized).
  /// `-60007` = errAuthorizationInteractionNotAllowed.
  /// `-60008` = errAuthorizationInternal.
  static bool _isPrivilegeDenial(String stderr) {
    if (stderr.contains('User canceled') ||
        stderr.contains('User cancelled') ||
        stderr.contains('-128')) {
      return true;
    }
    return RegExp(r'-6000[0-9]').hasMatch(stderr);
  }

  static String _describePrivilegeDenial(String stderr) {
    if (stderr.contains('-60005')) {
      return 'administrator password was incorrect';
    }
    if (stderr.contains('-60006')) {
      return 'user is not authorized as an administrator';
    }
    if (stderr.contains('-60007')) {
      return 'admin prompt was not allowed (MDM / no GUI?)';
    }
    if (stderr.contains('-128') ||
        stderr.contains('User canceled') ||
        stderr.contains('User cancelled')) {
      return 'user canceled administrator prompt';
    }
    return 'administrator authorization failed';
  }
}
