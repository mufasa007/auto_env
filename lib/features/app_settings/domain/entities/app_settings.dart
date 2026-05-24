import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

/// Application-wide preferences persisted to `<appSupport>/auto_env/settings.json`.
///
/// All fields have safe defaults so a missing or corrupt file produces a
/// usable instance instead of blocking app boot.
@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    /// Visual theme. M3 ships light-only; the field is kept so future
    /// dark / system modes don't require a migration.
    @Default(AppThemeMode.light) AppThemeMode themeMode,

    /// Explicit UI locale tag (`'zh'` / `'en'`). `null` = follow system.
    String? locale,

    /// What the window's close button does. Default biases to tray-friendly
    /// behavior because this app is meant to be long-running.
    @Default(CloseAction.hideToTray) CloseAction closeAction,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}

enum AppThemeMode { light, dark, system }

enum CloseAction { hideToTray, quit }
