import 'dart:io';

/// Resolves the platform-specific hosts file location. Injectable so tests
/// can point writers at a temp file instead of `/etc/hosts`.
class HostsFilePath {
  const HostsFilePath({this.override});

  final String? override;

  String resolve() {
    if (override != null) return override!;
    if (Platform.isWindows) {
      return r'C:\Windows\System32\drivers\etc\hosts';
    }
    return '/etc/hosts';
  }
}
