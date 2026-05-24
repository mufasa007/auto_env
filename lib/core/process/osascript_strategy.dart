import 'dart:io';

import 'elevation_strategy.dart';
import 'process_runner.dart';

/// Legacy elevation path: every command is wrapped in
/// `osascript -e 'do shell script "..." with administrator privileges'`, which
/// asks the user for Touch ID / password each time. Kept as a fallback for
/// hosts where the Authorization Services method channel is not available
/// (capability check failed at startup) and for tests / non-macOS callers that
/// just want to mock the elevation seam without touching Swift.
class OsascriptStrategy implements ElevationStrategy {
  const OsascriptStrategy({required this.processRunner});

  final ProcessRunner processRunner;

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? stdin,
  }) {
    final script = _buildScript(executable, arguments);
    return processRunner.run('osascript', ['-e', script], stdin: stdin);
  }

  static String _buildScript(String executable, List<String> arguments) {
    final cmd = StringBuffer(_quote(executable));
    for (final arg in arguments) {
      cmd
        ..write(' ')
        ..write(_quote(arg));
    }
    return 'do shell script "$cmd" with administrator privileges';
  }

  /// Wrap a single argv element so the resulting AppleScript string literal
  /// survives both the AppleScript and shell layers. `"` → `\\"`, `\\` → `\\\\`.
  static String _quote(String value) {
    final escaped = value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    return '\\"$escaped\\"';
  }
}
