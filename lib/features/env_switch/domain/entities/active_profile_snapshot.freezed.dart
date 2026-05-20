// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'active_profile_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ActiveProfileSnapshot _$ActiveProfileSnapshotFromJson(
  Map<String, dynamic> json,
) {
  return _ActiveProfileSnapshot.fromJson(json);
}

/// @nodoc
mixin _$ActiveProfileSnapshot {
  String get activeProfileId => throw _privateConstructorUsedError;
  DateTime get activatedAt => throw _privateConstructorUsedError;

  /// Serializes this ActiveProfileSnapshot to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ActiveProfileSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActiveProfileSnapshotCopyWith<ActiveProfileSnapshot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActiveProfileSnapshotCopyWith<$Res> {
  factory $ActiveProfileSnapshotCopyWith(
    ActiveProfileSnapshot value,
    $Res Function(ActiveProfileSnapshot) then,
  ) = _$ActiveProfileSnapshotCopyWithImpl<$Res, ActiveProfileSnapshot>;
  @useResult
  $Res call({String activeProfileId, DateTime activatedAt});
}

/// @nodoc
class _$ActiveProfileSnapshotCopyWithImpl<
  $Res,
  $Val extends ActiveProfileSnapshot
>
    implements $ActiveProfileSnapshotCopyWith<$Res> {
  _$ActiveProfileSnapshotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ActiveProfileSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? activeProfileId = null, Object? activatedAt = null}) {
    return _then(
      _value.copyWith(
            activeProfileId: null == activeProfileId
                ? _value.activeProfileId
                : activeProfileId // ignore: cast_nullable_to_non_nullable
                      as String,
            activatedAt: null == activatedAt
                ? _value.activatedAt
                : activatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ActiveProfileSnapshotImplCopyWith<$Res>
    implements $ActiveProfileSnapshotCopyWith<$Res> {
  factory _$$ActiveProfileSnapshotImplCopyWith(
    _$ActiveProfileSnapshotImpl value,
    $Res Function(_$ActiveProfileSnapshotImpl) then,
  ) = __$$ActiveProfileSnapshotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String activeProfileId, DateTime activatedAt});
}

/// @nodoc
class __$$ActiveProfileSnapshotImplCopyWithImpl<$Res>
    extends
        _$ActiveProfileSnapshotCopyWithImpl<$Res, _$ActiveProfileSnapshotImpl>
    implements _$$ActiveProfileSnapshotImplCopyWith<$Res> {
  __$$ActiveProfileSnapshotImplCopyWithImpl(
    _$ActiveProfileSnapshotImpl _value,
    $Res Function(_$ActiveProfileSnapshotImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ActiveProfileSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? activeProfileId = null, Object? activatedAt = null}) {
    return _then(
      _$ActiveProfileSnapshotImpl(
        activeProfileId: null == activeProfileId
            ? _value.activeProfileId
            : activeProfileId // ignore: cast_nullable_to_non_nullable
                  as String,
        activatedAt: null == activatedAt
            ? _value.activatedAt
            : activatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ActiveProfileSnapshotImpl implements _ActiveProfileSnapshot {
  const _$ActiveProfileSnapshotImpl({
    required this.activeProfileId,
    required this.activatedAt,
  });

  factory _$ActiveProfileSnapshotImpl.fromJson(Map<String, dynamic> json) =>
      _$$ActiveProfileSnapshotImplFromJson(json);

  @override
  final String activeProfileId;
  @override
  final DateTime activatedAt;

  @override
  String toString() {
    return 'ActiveProfileSnapshot(activeProfileId: $activeProfileId, activatedAt: $activatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActiveProfileSnapshotImpl &&
            (identical(other.activeProfileId, activeProfileId) ||
                other.activeProfileId == activeProfileId) &&
            (identical(other.activatedAt, activatedAt) ||
                other.activatedAt == activatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, activeProfileId, activatedAt);

  /// Create a copy of ActiveProfileSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActiveProfileSnapshotImplCopyWith<_$ActiveProfileSnapshotImpl>
  get copyWith =>
      __$$ActiveProfileSnapshotImplCopyWithImpl<_$ActiveProfileSnapshotImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ActiveProfileSnapshotImplToJson(this);
  }
}

abstract class _ActiveProfileSnapshot implements ActiveProfileSnapshot {
  const factory _ActiveProfileSnapshot({
    required final String activeProfileId,
    required final DateTime activatedAt,
  }) = _$ActiveProfileSnapshotImpl;

  factory _ActiveProfileSnapshot.fromJson(Map<String, dynamic> json) =
      _$ActiveProfileSnapshotImpl.fromJson;

  @override
  String get activeProfileId;
  @override
  DateTime get activatedAt;

  /// Create a copy of ActiveProfileSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActiveProfileSnapshotImplCopyWith<_$ActiveProfileSnapshotImpl>
  get copyWith => throw _privateConstructorUsedError;
}
