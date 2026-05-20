import 'dart:convert';
import 'dart:io';

import '../../../../core/process/process_runner.dart';
import '../../domain/entities/hosts_managed_block.dart';
import '../../domain/exceptions.dart';
import 'hosts_writer.dart';

/// Writes hosts on Windows via a sidecar helper exe that is marked
/// `requireAdministrator` in its manifest. Spawning the helper triggers a
/// single UAC prompt; the helper reads a JSON payload from stdin and writes
/// the file with elevated privileges.
///
/// `ipconfig /flushdns` does not require admin and is run from the main
/// process after the elevated write succeeds.
class WindowsHostsWriter implements HostsWriter {
  WindowsHostsWriter({
    required this.hostsFilePath,
    required this.helperExePath,
    required this.processRunner,
  });

  final String hostsFilePath;
  final String helperExePath;
  final ProcessRunner processRunner;

  /// Windows returns 1223 (ERROR_CANCELLED) when the user clicks "No" on UAC.
  static const int _errorCancelled = 1223;

  @override
  Future<String?> readExistingManagedBlock() async {
    final file = File(hostsFilePath);
    if (!await file.exists()) return null;
    final raw = await file.readAsString();
    return HostsManagedBlock.split(raw).existingBlock;
  }

  @override
  Future<void> applyManagedBlock(String newBlock) async {
    final helper = File(helperExePath);
    if (!await helper.exists()) {
      throw HostsWriteFailedException('helper missing: $helperExePath');
    }

    final payload = jsonEncode({
      'hostsPath': hostsFilePath,
      'managedBlock': newBlock,
      'markerStart': HostsManagedBlock.markerStart,
      'markerEnd': HostsManagedBlock.markerEnd,
    });

    final result =
        await processRunner.run(helperExePath, const [], stdin: payload);
    if (result.exitCode == _errorCancelled) {
      throw const PrivilegeDeniedException('user denied UAC prompt');
    }
    if (result.exitCode != 0) {
      throw HostsWriteFailedException(
        'helper exit ${result.exitCode}: ${result.stderr}${result.stdout}',
      );
    }

    // DNS flush is best-effort and runs without admin.
    try {
      await processRunner.run('ipconfig', const ['/flushdns']);
    } catch (_) {
      // non-fatal: hosts already written
    }
  }
}
