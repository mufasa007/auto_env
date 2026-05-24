import 'dart:io';

/// Pluggable strategy for executing shell commands that require administrator
/// privileges. macOS picks between the Authorization Services bridge (cached
/// `AuthorizationRef` — no prompt after first use within a session) and
/// `osascript with administrator privileges` (prompts every time) at startup;
/// other platforms either don't need elevation (env var writers) or use their
/// own native path (Windows helper.exe).
abstract class ElevationStrategy {
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? stdin,
  });
}
