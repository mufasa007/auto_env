import 'package:freezed_annotation/freezed_annotation.dart';

part 'last_switch_state.freezed.dart';
part 'last_switch_state.g.dart';

@freezed
class LastSwitchState with _$LastSwitchState {
  const factory LastSwitchState({
    String? previousActiveId,
    String? hostsManagedBlock,
    @Default(<String, String?>{}) Map<String, String?> envVarsApplied,
    required DateTime timestamp,
  }) = _LastSwitchState;

  factory LastSwitchState.fromJson(Map<String, dynamic> json) =>
      _$LastSwitchStateFromJson(json);
}
