import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Thin testable seam over [Process.start]. Production runs spawn a real
/// process; tests mock this interface to assert on arguments and inject
/// canned [ProcessResult]s without touching the host system.
abstract class ProcessRunner {
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? stdin,
  });
}

class DefaultProcessRunner implements ProcessRunner {
  const DefaultProcessRunner();

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? stdin,
  }) async {
    if (stdin == null) {
      return Process.run(executable, arguments, runInShell: false);
    }
    final process = await Process.start(
      executable,
      arguments,
      runInShell: false,
    );
    process.stdin.write(stdin);
    await process.stdin.close();
    final stdoutFut = process.stdout.transform(utf8.decoder).join();
    final stderrFut = process.stderr.transform(utf8.decoder).join();
    final exitCode = await process.exitCode;
    return ProcessResult(
      process.pid,
      exitCode,
      await stdoutFut,
      await stderrFut,
    );
  }
}
