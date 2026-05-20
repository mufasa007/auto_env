// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'env_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EnvProfileImpl _$$EnvProfileImplFromJson(Map<String, dynamic> json) =>
    _$EnvProfileImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      hostsEntries:
          (json['hostsEntries'] as List<dynamic>?)
              ?.map((e) => HostsEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <HostsEntry>[],
      envVars:
          (json['envVars'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$EnvProfileImplToJson(_$EnvProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'hostsEntries': instance.hostsEntries.map((e) => e.toJson()).toList(),
      'envVars': instance.envVars,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
