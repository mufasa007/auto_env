// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_profile_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ActiveProfileSnapshotImpl _$$ActiveProfileSnapshotImplFromJson(
  Map<String, dynamic> json,
) => _$ActiveProfileSnapshotImpl(
  activeProfileId: json['activeProfileId'] as String,
  activatedAt: DateTime.parse(json['activatedAt'] as String),
);

Map<String, dynamic> _$$ActiveProfileSnapshotImplToJson(
  _$ActiveProfileSnapshotImpl instance,
) => <String, dynamic>{
  'activeProfileId': instance.activeProfileId,
  'activatedAt': instance.activatedAt.toIso8601String(),
};
