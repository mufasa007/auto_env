// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'last_switch_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LastSwitchState _$LastSwitchStateFromJson(Map<String, dynamic> json) {
  return _LastSwitchState.fromJson(json);
}

/// @nodoc
mixin _$LastSwitchState {
  String? get previousActiveId => throw _privateConstructorUsedError;
  String? get hostsManagedBlock => throw _privateConstructorUsedError;
  Map<String, String?> get envVarsApplied => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Serializes this LastSwitchState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LastSwitchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LastSwitchStateCopyWith<LastSwitchState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LastSwitchStateCopyWith<$Res> {
  factory $LastSwitchStateCopyWith(
    LastSwitchState value,
    $Res Function(LastSwitchState) then,
  ) = _$LastSwitchStateCopyWithImpl<$Res, LastSwitchState>;
  @useResult
  $Res call({
    String? previousActiveId,
    String? hostsManagedBlock,
    Map<String, String?> envVarsApplied,
    DateTime timestamp,
  });
}

/// @nodoc
class _$LastSwitchStateCopyWithImpl<$Res, $Val extends LastSwitchState>
    implements $LastSwitchStateCopyWith<$Res> {
  _$LastSwitchStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LastSwitchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? previousActiveId = freezed,
    Object? hostsManagedBlock = freezed,
    Object? envVarsApplied = null,
    Object? timestamp = null,
  }) {
    return _then(
      _value.copyWith(
            previousActiveId: freezed == previousActiveId
                ? _value.previousActiveId
                : previousActiveId // ignore: cast_nullable_to_non_nullable
                      as String?,
            hostsManagedBlock: freezed == hostsManagedBlock
                ? _value.hostsManagedBlock
                : hostsManagedBlock // ignore: cast_nullable_to_non_nullable
                      as String?,
            envVarsApplied: null == envVarsApplied
                ? _value.envVarsApplied
                : envVarsApplied // ignore: cast_nullable_to_non_nullable
                      as Map<String, String?>,
            timestamp: null == timestamp
                ? _value.timestamp
                : timestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LastSwitchStateImplCopyWith<$Res>
    implements $LastSwitchStateCopyWith<$Res> {
  factory _$$LastSwitchStateImplCopyWith(
    _$LastSwitchStateImpl value,
    $Res Function(_$LastSwitchStateImpl) then,
  ) = __$$LastSwitchStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? previousActiveId,
    String? hostsManagedBlock,
    Map<String, String?> envVarsApplied,
    DateTime timestamp,
  });
}

/// @nodoc
class __$$LastSwitchStateImplCopyWithImpl<$Res>
    extends _$LastSwitchStateCopyWithImpl<$Res, _$LastSwitchStateImpl>
    implements _$$LastSwitchStateImplCopyWith<$Res> {
  __$$LastSwitchStateImplCopyWithImpl(
    _$LastSwitchStateImpl _value,
    $Res Function(_$LastSwitchStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LastSwitchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? previousActiveId = freezed,
    Object? hostsManagedBlock = freezed,
    Object? envVarsApplied = null,
    Object? timestamp = null,
  }) {
    return _then(
      _$LastSwitchStateImpl(
        previousActiveId: freezed == previousActiveId
            ? _value.previousActiveId
            : previousActiveId // ignore: cast_nullable_to_non_nullable
                  as String?,
        hostsManagedBlock: freezed == hostsManagedBlock
            ? _value.hostsManagedBlock
            : hostsManagedBlock // ignore: cast_nullable_to_non_nullable
                  as String?,
        envVarsApplied: null == envVarsApplied
            ? _value._envVarsApplied
            : envVarsApplied // ignore: cast_nullable_to_non_nullable
                  as Map<String, String?>,
        timestamp: null == timestamp
            ? _value.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LastSwitchStateImpl implements _LastSwitchState {
  const _$LastSwitchStateImpl({
    this.previousActiveId,
    this.hostsManagedBlock,
    final Map<String, String?> envVarsApplied = const <String, String?>{},
    required this.timestamp,
  }) : _envVarsApplied = envVarsApplied;

  factory _$LastSwitchStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$LastSwitchStateImplFromJson(json);

  @override
  final String? previousActiveId;
  @override
  final String? hostsManagedBlock;
  final Map<String, String?> _envVarsApplied;
  @override
  @JsonKey()
  Map<String, String?> get envVarsApplied {
    if (_envVarsApplied is EqualUnmodifiableMapView) return _envVarsApplied;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_envVarsApplied);
  }

  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'LastSwitchState(previousActiveId: $previousActiveId, hostsManagedBlock: $hostsManagedBlock, envVarsApplied: $envVarsApplied, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LastSwitchStateImpl &&
            (identical(other.previousActiveId, previousActiveId) ||
                other.previousActiveId == previousActiveId) &&
            (identical(other.hostsManagedBlock, hostsManagedBlock) ||
                other.hostsManagedBlock == hostsManagedBlock) &&
            const DeepCollectionEquality().equals(
              other._envVarsApplied,
              _envVarsApplied,
            ) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    previousActiveId,
    hostsManagedBlock,
    const DeepCollectionEquality().hash(_envVarsApplied),
    timestamp,
  );

  /// Create a copy of LastSwitchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LastSwitchStateImplCopyWith<_$LastSwitchStateImpl> get copyWith =>
      __$$LastSwitchStateImplCopyWithImpl<_$LastSwitchStateImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$LastSwitchStateImplToJson(this);
  }
}

abstract class _LastSwitchState implements LastSwitchState {
  const factory _LastSwitchState({
    final String? previousActiveId,
    final String? hostsManagedBlock,
    final Map<String, String?> envVarsApplied,
    required final DateTime timestamp,
  }) = _$LastSwitchStateImpl;

  factory _LastSwitchState.fromJson(Map<String, dynamic> json) =
      _$LastSwitchStateImpl.fromJson;

  @override
  String? get previousActiveId;
  @override
  String? get hostsManagedBlock;
  @override
  Map<String, String?> get envVarsApplied;
  @override
  DateTime get timestamp;

  /// Create a copy of LastSwitchState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LastSwitchStateImplCopyWith<_$LastSwitchStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
