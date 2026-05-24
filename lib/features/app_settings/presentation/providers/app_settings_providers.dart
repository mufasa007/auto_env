import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../env_profile/presentation/providers/env_profile_providers.dart';
import '../../data/repositories/app_settings_json_repository.dart';
import '../../data/repositories/app_settings_repository.dart';
import '../../domain/entities/app_settings.dart';

/// Resolves the [AppSettingsRepository] backed by `<appSupport>/auto_env/settings.json`.
/// Tests override [appPathsProvider] to point at a temp dir.
final appSettingsRepositoryProvider =
    FutureProvider<AppSettingsRepository>((ref) async {
  final paths = ref.watch(appPathsProvider);
  final file = await paths.appSettingsFile();
  return AppSettingsJsonRepository(file: file);
});

/// App-wide [AppSettings]. Watched by [MaterialApp] for `themeMode` / `locale`
/// and by the tray controller for `closeAction`. Persists every mutation.
final appSettingsNotifierProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  Future<AppSettingsRepository> get _repo =>
      ref.read(appSettingsRepositoryProvider.future);

  @override
  Future<AppSettings> build() async {
    final repo = await _repo;
    return repo.get();
  }

  Future<void> updateThemeMode(AppThemeMode mode) =>
      _mutate((s) => s.copyWith(themeMode: mode));

  Future<void> updateLocale(String? locale) =>
      _mutate((s) => s.copyWith(locale: locale));

  Future<void> updateCloseAction(CloseAction action) =>
      _mutate((s) => s.copyWith(closeAction: action));

  Future<void> _mutate(AppSettings Function(AppSettings) transform) async {
    final current = state.value ?? const AppSettings();
    final next = transform(current);
    state = AsyncData(next); // optimistic, settings UI is interactive
    try {
      final repo = await _repo;
      await repo.save(next);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Maps [AppThemeMode] to Flutter's [ThemeMode]. Convenience for MaterialApp.
ThemeMode toFlutterThemeMode(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
    case AppThemeMode.system:
      return ThemeMode.system;
  }
}

/// Maps explicit locale tag (`'zh'` / `'en'` / `null`) to a [Locale] usable by
/// MaterialApp. `null` returns `null` so Flutter falls back to the system
/// locale.
Locale? toFlutterLocale(String? tag) {
  if (tag == null || tag.isEmpty) return null;
  return Locale(tag);
}
