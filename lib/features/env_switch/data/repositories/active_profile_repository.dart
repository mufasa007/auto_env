import '../../domain/entities/active_profile_snapshot.dart';

abstract class ActiveProfileRepository {
  Future<ActiveProfileSnapshot?> get();
  Future<void> save(ActiveProfileSnapshot snapshot);
  Future<void> clear();
}
