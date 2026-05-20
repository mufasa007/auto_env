import 'dart:io';

import '../../../../core/process/process_runner.dart';
import '../../../../core/storage/atomic_file_writer.dart';
import '../../domain/exceptions.dart';
import 'env_var_writer.dart';

/// macOS env var writer.
///
/// Dual mechanism so the var is visible to both GUI apps and shells:
///   1. `launchctl setenv KEY VALUE` — picked up by GUI apps launched from
///      Finder / Spotlight after the call.
///   2. Rewrites `~/.config/auto_env/env.sh`. User adds a one-time line to
///      their shell rc:
///        `[ -f ~/.config/auto_env/env.sh ] && source ~/.config/auto_env/env.sh`
///      Shells sourced after the rewrite see the new values.
class MacosEnvVarWriter implements EnvVarWriter {
  MacosEnvVarWriter({
    required this.processRunner,
    required this.shellFile,
  });

  final ProcessRunner processRunner;
  final File shellFile;

  @override
  Future<void> apply(
    Map<String, String> next,
    Map<String, String?> previous,
  ) async {
    for (final entry in next.entries) {
      final result = await processRunner.run(
        'launchctl',
        ['setenv', entry.key, entry.value],
      );
      if (result.exitCode != 0) {
        throw EnvVarWriteFailedException(
          'launchctl setenv ${entry.key} failed: ${result.stderr}',
        );
      }
    }
    for (final key in previous.keys) {
      if (next.containsKey(key)) continue;
      final result = await processRunner.run('launchctl', ['unsetenv', key]);
      if (result.exitCode != 0) {
        throw EnvVarWriteFailedException(
          'launchctl unsetenv $key failed: ${result.stderr}',
        );
      }
    }

    final buf = StringBuffer()
      ..writeln('# >>> auto_env env >>>')
      ..writeln('# Managed by auto_env. Source from your shell rc:')
      ..writeln(
        '#   [ -f ~/.config/auto_env/env.sh ] && source ~/.config/auto_env/env.sh',
      );
    for (final entry in next.entries) {
      buf.writeln('export ${entry.key}="${_escapeShell(entry.value)}"');
    }
    buf.writeln('# <<< auto_env env <<<');

    await AtomicFileWriter(file: shellFile).write(buf.toString());
  }

  /// Escapes for embedding inside a double-quoted shell string.
  static String _escapeShell(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll(r'"', r'\"')
        .replaceAll(r'$', r'\$')
        .replaceAll('`', r'\`');
  }
}
