import '../../domain/entities/app_settings.dart';

abstract class AppSettingsRepository {
  Future<AppSettings> get();
  Future<void> save(AppSettings settings);
}
