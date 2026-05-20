import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract class AppPaths {
  /// `<appSupportDir>/auto_env/profiles.json` — all environment profiles.
  Future<File> envProfilesFile();

  /// `<appSupportDir>/auto_env/active.json` — id of the currently active
  /// profile + activation timestamp.
  Future<File> activeProfileFile();

  /// `<appSupportDir>/auto_env/last_state.json` — snapshot taken right before
  /// the most recent switch attempt, used for rollback.
  Future<File> lastSwitchStateFile();

  /// `~/.config/auto_env/env.sh` on macOS, `null` elsewhere.
  /// Users source this from their shell rc to make env vars visible to shells.
  Future<File?> userEnvShellFile();
}

class DefaultAppPaths implements AppPaths {
  const DefaultAppPaths();

  Future<Directory> _autoEnvDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/auto_env');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  @override
  Future<File> envProfilesFile() async {
    final dir = await _autoEnvDir();
    return File('${dir.path}/profiles.json');
  }

  @override
  Future<File> activeProfileFile() async {
    final dir = await _autoEnvDir();
    return File('${dir.path}/active.json');
  }

  @override
  Future<File> lastSwitchStateFile() async {
    final dir = await _autoEnvDir();
    return File('${dir.path}/last_state.json');
  }

  @override
  Future<File?> userEnvShellFile() async {
    if (!Platform.isMacOS) return null;
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) return null;
    final dir = Directory('$home/.config/auto_env');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File('${dir.path}/env.sh');
  }
}
