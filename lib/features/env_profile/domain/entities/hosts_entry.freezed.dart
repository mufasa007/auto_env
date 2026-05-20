// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hosts_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

HostsEntry _$HostsEntryFromJson(Map<String, dynamic> json) {
  return _HostsEntry.fromJson(json);
}

/// @nodoc
mixin _$HostsEntry {
  String get ip => throw _privateConstructorUsedError;
  String get hostname => throw _privateConstructorUsedError;
  bool get enabled => throw _privateConstructorUsedError;

  /// Serializes this HostsEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HostsEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HostsEntryCopyWith<HostsEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HostsEntryCopyWith<$Res> {
  factory $HostsEntryCopyWith(
    HostsEntry value,
    $Res Function(HostsEntry) then,
  ) = _$HostsEntryCopyWithImpl<$Res, HostsEntry>;
  @useResult
  $Res call({String ip, String hostname, bool enabled});
}

/// @nodoc
class _$HostsEntryCopyWithImpl<$Res, $Val extends HostsEntry>
    implements $HostsEntryCopyWith<$Res> {
  _$HostsEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HostsEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ip = null,
    Object? hostname = null,
    Object? enabled = null,
  }) {
    return _then(
      _value.copyWith(
            ip: null == ip
                ? _value.ip
                : ip // ignore: cast_nullable_to_non_nullable
                      as String,
            hostname: null == hostname
                ? _value.hostname
                : hostname // ignore: cast_nullable_to_non_nullable
                      as String,
            enabled: null == enabled
                ? _value.enabled
                : enabled // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HostsEntryImplCopyWith<$Res>
    implements $HostsEntryCopyWith<$Res> {
  factory _$$HostsEntryImplCopyWith(
    _$HostsEntryImpl value,
    $Res Function(_$HostsEntryImpl) then,
  ) = __$$HostsEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String ip, String hostname, bool enabled});
}

/// @nodoc
class __$$HostsEntryImplCopyWithImpl<$Res>
    extends _$HostsEntryCopyWithImpl<$Res, _$HostsEntryImpl>
    implements _$$HostsEntryImplCopyWith<$Res> {
  __$$HostsEntryImplCopyWithImpl(
    _$HostsEntryImpl _value,
    $Res Function(_$HostsEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HostsEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ip = null,
    Object? hostname = null,
    Object? enabled = null,
  }) {
    return _then(
      _$HostsEntryImpl(
        ip: null == ip
            ? _value.ip
            : ip // ignore: cast_nullable_to_non_nullable
                  as String,
        hostname: null == hostname
            ? _value.hostname
            : hostname // ignore: cast_nullable_to_non_nullable
                  as String,
        enabled: null == enabled
            ? _value.enabled
            : enabled // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HostsEntryImpl implements _HostsEntry {
  const _$HostsEntryImpl({
    required this.ip,
    required this.hostname,
    this.enabled = true,
  });

  factory _$HostsEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$HostsEntryImplFromJson(json);

  @override
  final String ip;
  @override
  final String hostname;
  @override
  @JsonKey()
  final bool enabled;

  @override
  String toString() {
    return 'HostsEntry(ip: $ip, hostname: $hostname, enabled: $enabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HostsEntryImpl &&
            (identical(other.ip, ip) || other.ip == ip) &&
            (identical(other.hostname, hostname) ||
                other.hostname == hostname) &&
            (identical(other.enabled, enabled) || other.enabled == enabled));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, ip, hostname, enabled);

  /// Create a copy of HostsEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HostsEntryImplCopyWith<_$HostsEntryImpl> get copyWith =>
      __$$HostsEntryImplCopyWithImpl<_$HostsEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HostsEntryImplToJson(this);
  }
}

abstract class _HostsEntry implements HostsEntry {
  const factory _HostsEntry({
    required final String ip,
    required final String hostname,
    final bool enabled,
  }) = _$HostsEntryImpl;

  factory _HostsEntry.fromJson(Map<String, dynamic> json) =
      _$HostsEntryImpl.fromJson;

  @override
  String get ip;
  @override
  String get hostname;
  @override
  bool get enabled;

  /// Create a copy of HostsEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HostsEntryImplCopyWith<_$HostsEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
