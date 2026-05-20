// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'env_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

EnvProfile _$EnvProfileFromJson(Map<String, dynamic> json) {
  return _EnvProfile.fromJson(json);
}

/// @nodoc
mixin _$EnvProfile {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<HostsEntry> get hostsEntries => throw _privateConstructorUsedError;
  Map<String, String> get envVars => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this EnvProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EnvProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EnvProfileCopyWith<EnvProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EnvProfileCopyWith<$Res> {
  factory $EnvProfileCopyWith(
    EnvProfile value,
    $Res Function(EnvProfile) then,
  ) = _$EnvProfileCopyWithImpl<$Res, EnvProfile>;
  @useResult
  $Res call({
    String id,
    String name,
    List<HostsEntry> hostsEntries,
    Map<String, String> envVars,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$EnvProfileCopyWithImpl<$Res, $Val extends EnvProfile>
    implements $EnvProfileCopyWith<$Res> {
  _$EnvProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EnvProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? hostsEntries = null,
    Object? envVars = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            hostsEntries: null == hostsEntries
                ? _value.hostsEntries
                : hostsEntries // ignore: cast_nullable_to_non_nullable
                      as List<HostsEntry>,
            envVars: null == envVars
                ? _value.envVars
                : envVars // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EnvProfileImplCopyWith<$Res>
    implements $EnvProfileCopyWith<$Res> {
  factory _$$EnvProfileImplCopyWith(
    _$EnvProfileImpl value,
    $Res Function(_$EnvProfileImpl) then,
  ) = __$$EnvProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    List<HostsEntry> hostsEntries,
    Map<String, String> envVars,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$EnvProfileImplCopyWithImpl<$Res>
    extends _$EnvProfileCopyWithImpl<$Res, _$EnvProfileImpl>
    implements _$$EnvProfileImplCopyWith<$Res> {
  __$$EnvProfileImplCopyWithImpl(
    _$EnvProfileImpl _value,
    $Res Function(_$EnvProfileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EnvProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? hostsEntries = null,
    Object? envVars = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$EnvProfileImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        hostsEntries: null == hostsEntries
            ? _value._hostsEntries
            : hostsEntries // ignore: cast_nullable_to_non_nullable
                  as List<HostsEntry>,
        envVars: null == envVars
            ? _value._envVars
            : envVars // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EnvProfileImpl implements _EnvProfile {
  const _$EnvProfileImpl({
    required this.id,
    required this.name,
    final List<HostsEntry> hostsEntries = const <HostsEntry>[],
    final Map<String, String> envVars = const <String, String>{},
    required this.createdAt,
    required this.updatedAt,
  }) : _hostsEntries = hostsEntries,
       _envVars = envVars;

  factory _$EnvProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$EnvProfileImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  final List<HostsEntry> _hostsEntries;
  @override
  @JsonKey()
  List<HostsEntry> get hostsEntries {
    if (_hostsEntries is EqualUnmodifiableListView) return _hostsEntries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hostsEntries);
  }

  final Map<String, String> _envVars;
  @override
  @JsonKey()
  Map<String, String> get envVars {
    if (_envVars is EqualUnmodifiableMapView) return _envVars;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_envVars);
  }

  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'EnvProfile(id: $id, name: $name, hostsEntries: $hostsEntries, envVars: $envVars, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EnvProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(
              other._hostsEntries,
              _hostsEntries,
            ) &&
            const DeepCollectionEquality().equals(other._envVars, _envVars) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    const DeepCollectionEquality().hash(_hostsEntries),
    const DeepCollectionEquality().hash(_envVars),
    createdAt,
    updatedAt,
  );

  /// Create a copy of EnvProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EnvProfileImplCopyWith<_$EnvProfileImpl> get copyWith =>
      __$$EnvProfileImplCopyWithImpl<_$EnvProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EnvProfileImplToJson(this);
  }
}

abstract class _EnvProfile implements EnvProfile {
  const factory _EnvProfile({
    required final String id,
    required final String name,
    final List<HostsEntry> hostsEntries,
    final Map<String, String> envVars,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$EnvProfileImpl;

  factory _EnvProfile.fromJson(Map<String, dynamic> json) =
      _$EnvProfileImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  List<HostsEntry> get hostsEntries;
  @override
  Map<String, String> get envVars;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of EnvProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EnvProfileImplCopyWith<_$EnvProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
