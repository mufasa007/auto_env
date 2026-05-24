import 'dart:convert';
import 'dart:io';

import '../../../../core/storage/atomic_file_writer.dart';
import '../../domain/entities/app_settings.dart';
import 'app_settings_repository.dart';

/// Persists [AppSettings] to `<appSupport>/auto_env/settings.json`.
///
/// Corruption policy: a missing, empty, or malformed file resolves to
/// `AppSettings()` defaults rather than throwing — settings are
/// user-tweakable convenience state, never the source of truth for any
/// switching behavior.
class AppSettingsJsonRepository implements AppSettingsRepository {
  AppSettingsJsonRepository({required this.file})
      : _writer = AtomicFileWriter(file: file);

  final File file;
  final AtomicFileWriter _writer;

  @override
  Future<AppSettings> get() async {
    if (!await file.exists()) return const AppSettings();
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return const AppSettings();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const AppSettings();
      return AppSettings.fromJson(decoded);
    } catch (_) {
      return const AppSettings();
    }
  }

  @override
  Future<void> save(AppSettings settings) {
    return _writer.write(jsonEncode(settings.toJson()));
  }
}
