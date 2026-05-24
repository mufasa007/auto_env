import 'dart:io';

import 'package:auto_env/core/storage/app_paths.dart';
import 'package:auto_env/features/app_settings/domain/entities/app_settings.dart';
import 'package:auto_env/features/app_settings/presentation/providers/app_settings_providers.dart';
import 'package:auto_env/features/env_profile/presentation/providers/env_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TempAppPaths implements AppPaths {
  _TempAppPaths(this._dir);
  final Directory _dir;
  @override
  Future<File> appSettingsFile() async =>
      File('${_dir.path}/settings.json');
  @override
  Future<File> envProfilesFile() async =>
      File('${_dir.path}/profiles.json');
  @override
  Future<File> activeProfileFile() async =>
      File('${_dir.path}/active.json');
  @override
  Future<File> lastSwitchStateFile() async =>
      File('${_dir.path}/last_state.json');
  @override
  Future<File?> userEnvShellFile() async => null;
}

void main() {
  late Directory tempDir;
  late ProviderContainer container;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('auto_env_settings_prov_');
    container = ProviderContainer(
      overrides: [
        appPathsProvider.overrideWithValue(_TempAppPaths(tempDir)),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('build() returns persisted settings (or defaults on first run)',
      () async {
    final loaded = await container.read(appSettingsNotifierProvider.future);
    expect(loaded, const AppSettings());
  });

  test('updateThemeMode persists + updates state', () async {
    await container.read(appSettingsNotifierProvider.future);
    final notifier = container.read(appSettingsNotifierProvider.notifier);

    await notifier.updateThemeMode(AppThemeMode.dark);

    expect(
      container.read(appSettingsNotifierProvider).requireValue.themeMode,
      AppThemeMode.dark,
    );

    // New container reads from disk -> still dark
    final container2 = ProviderContainer(overrides: [
      appPathsProvider.overrideWithValue(_TempAppPaths(tempDir)),
    ]);
    addTearDown(container2.dispose);
    final reloaded =
        await container2.read(appSettingsNotifierProvider.future);
    expect(reloaded.themeMode, AppThemeMode.dark);
  });

  test('updateLocale supports clearing back to null (follow system)',
      () async {
    await container.read(appSettingsNotifierProvider.future);
    final notifier = container.read(appSettingsNotifierProvider.notifier);

    await notifier.updateLocale('zh');
    expect(
      container.read(appSettingsNotifierProvider).requireValue.locale,
      'zh',
    );

    await notifier.updateLocale(null);
    expect(
      container.read(appSettingsNotifierProvider).requireValue.locale,
      isNull,
    );
  });

  test('updateCloseAction persists', () async {
    await container.read(appSettingsNotifierProvider.future);
    final notifier = container.read(appSettingsNotifierProvider.notifier);

    await notifier.updateCloseAction(CloseAction.quit);

    expect(
      container
          .read(appSettingsNotifierProvider)
          .requireValue
          .closeAction,
      CloseAction.quit,
    );
  });

  group('toFlutterThemeMode', () {
    test('maps each AppThemeMode to ThemeMode', () {
      expect(toFlutterThemeMode(AppThemeMode.light), ThemeMode.light);
      expect(toFlutterThemeMode(AppThemeMode.dark), ThemeMode.dark);
      expect(toFlutterThemeMode(AppThemeMode.system), ThemeMode.system);
    });
  });

  group('toFlutterLocale', () {
    test('null and empty produce null (follow system)', () {
      expect(toFlutterLocale(null), isNull);
      expect(toFlutterLocale(''), isNull);
    });

    test('explicit tag becomes Locale', () {
      expect(toFlutterLocale('zh'), const Locale('zh'));
      expect(toFlutterLocale('en'), const Locale('en'));
    });
  });
}
