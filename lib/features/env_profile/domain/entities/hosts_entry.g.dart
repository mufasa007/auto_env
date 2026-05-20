// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hosts_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HostsEntryImpl _$$HostsEntryImplFromJson(Map<String, dynamic> json) =>
    _$HostsEntryImpl(
      ip: json['ip'] as String,
      hostname: json['hostname'] as String,
      enabled: json['enabled'] as bool? ?? true,
    );

Map<String, dynamic> _$$HostsEntryImplToJson(_$HostsEntryImpl instance) =>
    <String, dynamic>{
      'ip': instance.ip,
      'hostname': instance.hostname,
      'enabled': instance.enabled,
    };
