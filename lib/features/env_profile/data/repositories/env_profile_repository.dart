import '../../domain/entities/env_profile.dart';

abstract class EnvProfileRepository {
  Future<List<EnvProfile>> list();

  Future<EnvProfile?> get(String id);

  Future<void> save(EnvProfile profile);

  Future<void> delete(String id);
}

sealed class EnvProfileException implements Exception {
  const EnvProfileException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class EnvProfileCorruptedException extends EnvProfileException {
  const EnvProfileCorruptedException(super.message);
}
