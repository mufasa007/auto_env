// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'last_switch_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LastSwitchStateImpl _$$LastSwitchStateImplFromJson(
  Map<String, dynamic> json,
) => _$LastSwitchStateImpl(
  previousActiveId: json['previousActiveId'] as String?,
  hostsManagedBlock: json['hostsManagedBlock'] as String?,
  envVarsApplied:
      (json['envVarsApplied'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String?),
      ) ??
      const <String, String?>{},
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$$LastSwitchStateImplToJson(
  _$LastSwitchStateImpl instance,
) => <String, dynamic>{
  'previousActiveId': instance.previousActiveId,
  'hostsManagedBlock': instance.hostsManagedBlock,
  'envVarsApplied': instance.envVarsApplied,
  'timestamp': instance.timestamp.toIso8601String(),
};
