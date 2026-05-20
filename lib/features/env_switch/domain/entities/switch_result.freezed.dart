// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'switch_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SwitchResult {
  String get profileId => throw _privateConstructorUsedError;
  Duration get elapsed => throw _privateConstructorUsedError;
  List<SwitchStage> get stages => throw _privateConstructorUsedError;

  /// Create a copy of SwitchResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SwitchResultCopyWith<SwitchResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SwitchResultCopyWith<$Res> {
  factory $SwitchResultCopyWith(
    SwitchResult value,
    $Res Function(SwitchResult) then,
  ) = _$SwitchResultCopyWithImpl<$Res, SwitchResult>;
  @useResult
  $Res call({String profileId, Duration elapsed, List<SwitchStage> stages});
}

/// @nodoc
class _$SwitchResultCopyWithImpl<$Res, $Val extends SwitchResult>
    implements $SwitchResultCopyWith<$Res> {
  _$SwitchResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SwitchResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? profileId = null,
    Object? elapsed = null,
    Object? stages = null,
  }) {
    return _then(
      _value.copyWith(
            profileId: null == profileId
                ? _value.profileId
                : profileId // ignore: cast_nullable_to_non_nullable
                      as String,
            elapsed: null == elapsed
                ? _value.elapsed
                : elapsed // ignore: cast_nullable_to_non_nullable
                      as Duration,
            stages: null == stages
                ? _value.stages
                : stages // ignore: cast_nullable_to_non_nullable
                      as List<SwitchStage>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SwitchResultImplCopyWith<$Res>
    implements $SwitchResultCopyWith<$Res> {
  factory _$$SwitchResultImplCopyWith(
    _$SwitchResultImpl value,
    $Res Function(_$SwitchResultImpl) then,
  ) = __$$SwitchResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String profileId, Duration elapsed, List<SwitchStage> stages});
}

/// @nodoc
class __$$SwitchResultImplCopyWithImpl<$Res>
    extends _$SwitchResultCopyWithImpl<$Res, _$SwitchResultImpl>
    implements _$$SwitchResultImplCopyWith<$Res> {
  __$$SwitchResultImplCopyWithImpl(
    _$SwitchResultImpl _value,
    $Res Function(_$SwitchResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SwitchResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? profileId = null,
    Object? elapsed = null,
    Object? stages = null,
  }) {
    return _then(
      _$SwitchResultImpl(
        profileId: null == profileId
            ? _value.profileId
            : profileId // ignore: cast_nullable_to_non_nullable
                  as String,
        elapsed: null == elapsed
            ? _value.elapsed
            : elapsed // ignore: cast_nullable_to_non_nullable
                  as Duration,
        stages: null == stages
            ? _value._stages
            : stages // ignore: cast_nullable_to_non_nullable
                  as List<SwitchStage>,
      ),
    );
  }
}

/// @nodoc

class _$SwitchResultImpl implements _SwitchResult {
  const _$SwitchResultImpl({
    required this.profileId,
    required this.elapsed,
    final List<SwitchStage> stages = const <SwitchStage>[],
  }) : _stages = stages;

  @override
  final String profileId;
  @override
  final Duration elapsed;
  final List<SwitchStage> _stages;
  @override
  @JsonKey()
  List<SwitchStage> get stages {
    if (_stages is EqualUnmodifiableListView) return _stages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stages);
  }

  @override
  String toString() {
    return 'SwitchResult(profileId: $profileId, elapsed: $elapsed, stages: $stages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SwitchResultImpl &&
            (identical(other.profileId, profileId) ||
                other.profileId == profileId) &&
            (identical(other.elapsed, elapsed) || other.elapsed == elapsed) &&
            const DeepCollectionEquality().equals(other._stages, _stages));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    profileId,
    elapsed,
    const DeepCollectionEquality().hash(_stages),
  );

  /// Create a copy of SwitchResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SwitchResultImplCopyWith<_$SwitchResultImpl> get copyWith =>
      __$$SwitchResultImplCopyWithImpl<_$SwitchResultImpl>(this, _$identity);
}

abstract class _SwitchResult implements SwitchResult {
  const factory _SwitchResult({
    required final String profileId,
    required final Duration elapsed,
    final List<SwitchStage> stages,
  }) = _$SwitchResultImpl;

  @override
  String get profileId;
  @override
  Duration get elapsed;
  @override
  List<SwitchStage> get stages;

  /// Create a copy of SwitchResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SwitchResultImplCopyWith<_$SwitchResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
