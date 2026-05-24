import 'dart:io';

import 'package:auto_env/features/app_settings/data/repositories/app_settings_json_repository.dart';
import 'package:auto_env/features/app_settings/domain/entities/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late File settingsFile;
  late AppSettingsJsonRepository repo;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('auto_env_settings_');
    settingsFile = File('${tempDir.path}/settings.json');
    repo = AppSettingsJsonRepository(file: settingsFile);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('get() returns defaults when file does not exist', () async {
    final result = await repo.get();
    expect(result, const AppSettings());
    expect(result.themeMode, AppThemeMode.light);
    expect(result.locale, isNull);
    expect(result.closeAction, CloseAction.hideToTray);
  });

  test('get() returns defaults when file is empty', () async {
    await settingsFile.writeAsString('');
    final result = await repo.get();
    expect(result, const AppSettings());
  });

  test('get() returns defaults when file is malformed JSON', () async {
    await settingsFile.writeAsString('not json {{{');
    final result = await repo.get();
    expect(result, const AppSettings());
  });

  test('get() returns defaults when JSON root is not an object', () async {
    await settingsFile.writeAsString('[]');
    final result = await repo.get();
    expect(result, const AppSettings());
  });

  test('save() then get() round-trips every field', () async {
    const settings = AppSettings(
      themeMode: AppThemeMode.dark,
      locale: 'zh',
      closeAction: CloseAction.quit,
    );

    await repo.save(settings);
    final reloaded = await repo.get();

    expect(reloaded, settings);
  });

  test('save() writes atomically (no stale tmp file left behind)', () async {
    await repo.save(const AppSettings(locale: 'en'));

    final remaining = tempDir
        .listSync()
        .map((e) => e.uri.pathSegments.last)
        .toList();
    expect(remaining, ['settings.json']);
  });
}
