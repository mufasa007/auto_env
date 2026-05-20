import '../../domain/entities/last_switch_state.dart';

abstract class LastSwitchStateRepository {
  Future<LastSwitchState?> get();
  Future<void> save(LastSwitchState state);
  Future<void> clear();
}
