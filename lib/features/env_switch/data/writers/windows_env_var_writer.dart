import '../../../../core/process/process_runner.dart';
import '../../domain/exceptions.dart';
import 'env_var_writer.dart';

/// Windows env var writer.
///
/// Writes user-scope env vars directly to `HKCU\Environment` via the .NET
/// registry API, then issues a single bounded `WM_SETTINGCHANGE` broadcast
/// at the end.
///
/// The earlier implementation called `[Environment]::SetEnvironmentVariable(
/// ..., 'User')` per key. Each of those calls internally performs a
/// synchronous `SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, ...)`
/// with the .NET default 5s timeout. On a typical desktop with a few
/// unresponsive top-level windows this costs ~3s per call, so a 3-key
/// apply paid ~10s — well past the M2 plan's 5s SLO. Direct registry write
/// + one bounded broadcast brings the same apply step under 2s.
///
/// Values containing `%` are written as REG_EXPAND_SZ (matching .NET's
/// `Environment.SetEnvironmentVariable` behavior); otherwise REG_SZ. The
/// final broadcast uses `SMTO_ABORTIFHUNG` with a 1000ms cap so a single
/// hung window cannot stall the whole apply step.
class WindowsEnvVarWriter implements EnvVarWriter {
  WindowsEnvVarWriter({required this.processRunner});

  final ProcessRunner processRunner;

  @override
  Future<void> apply(
    Map<String, String> next,
    Map<String, String?> previous,
  ) async {
    final ops = <String>[];
    for (final entry in next.entries) {
      final kind = entry.value.contains('%') ? 'ExpandString' : 'String';
      ops.add(
        "\$key.SetValue('${_escapePs(entry.key)}','${_escapePs(entry.value)}',[Microsoft.Win32.RegistryValueKind]::$kind)",
      );
    }
    for (final key in previous.keys) {
      if (next.containsKey(key)) continue;
      ops.add("\$key.DeleteValue('${_escapePs(key)}',\$false)");
    }
    if (ops.isEmpty) return;

    final script = [
      r"$ErrorActionPreference='Stop'",
      r"$key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment',$true)",
      'try {',
      ops.join('; '),
      r'} finally { if ($key) { $key.Close() } }',
      "Add-Type -Namespace W -Name N -MemberDefinition '"
          '[System.Runtime.InteropServices.DllImport(\"user32.dll\",CharSet=System.Runtime.InteropServices.CharSet.Auto)]'
          'public static extern System.IntPtr SendMessageTimeout(System.IntPtr hWnd, uint Msg, System.UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out System.UIntPtr lpdwResult);'
          "'",
      r'$res = [System.UIntPtr]::Zero',
      r"[W.N]::SendMessageTimeout([System.IntPtr]0xffff,0x1A,[System.UIntPtr]::Zero,'Environment',0x0002,1000,[ref]$res) | Out-Null",
    ].join('\n');

    final result = await processRunner.run(
      'powershell',
      ['-NoProfile', '-Command', script],
    );
    if (result.exitCode != 0) {
      throw EnvVarWriteFailedException(
        'powershell registry write failed: ${result.stderr}',
      );
    }
  }

  /// PowerShell single-quoted strings escape `'` by doubling it.
  static String _escapePs(String s) => s.replaceAll("'", "''");
}
