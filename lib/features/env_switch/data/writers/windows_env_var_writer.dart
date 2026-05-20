import '../../../../core/process/process_runner.dart';
import '../../domain/exceptions.dart';
import 'env_var_writer.dart';

/// Windows env var writer.
///
/// Uses a single PowerShell invocation that batches all
/// `[Environment]::SetEnvironmentVariable(...)` calls into one process. This
/// is critical for the 5-second SLO — spawning PowerShell per variable costs
/// ~300-500ms each on cold Windows. Batching keeps the whole apply step
/// well under a second for any realistic var count.
///
/// `[Environment]::SetEnvironmentVariable` writes to HKCU\Environment AND
/// broadcasts `WM_SETTINGCHANGE` automatically, so Explorer / new shells
/// pick up the change without further work.
///
/// Passing `$null` as the value deletes the variable.
class WindowsEnvVarWriter implements EnvVarWriter {
  WindowsEnvVarWriter({required this.processRunner});

  final ProcessRunner processRunner;

  @override
  Future<void> apply(
    Map<String, String> next,
    Map<String, String?> previous,
  ) async {
    final commands = <String>[];
    for (final entry in next.entries) {
      commands.add(
        "[Environment]::SetEnvironmentVariable('${_escapePs(entry.key)}','${_escapePs(entry.value)}','User')",
      );
    }
    for (final key in previous.keys) {
      if (next.containsKey(key)) continue;
      commands.add(
        "[Environment]::SetEnvironmentVariable('${_escapePs(key)}',\$null,'User')",
      );
    }
    if (commands.isEmpty) return;

    final script = commands.join('; ');
    final result = await processRunner.run(
      'powershell',
      ['-NoProfile', '-Command', script],
    );
    if (result.exitCode != 0) {
      throw EnvVarWriteFailedException(
        'powershell SetEnvironmentVariable failed: ${result.stderr}',
      );
    }
  }

  /// PowerShell single-quoted strings escape `'` by doubling it.
  static String _escapePs(String s) => s.replaceAll("'", "''");
}
