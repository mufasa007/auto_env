import 'package:freezed_annotation/freezed_annotation.dart';

part 'active_profile_snapshot.freezed.dart';
part 'active_profile_snapshot.g.dart';

@freezed
class ActiveProfileSnapshot with _$ActiveProfileSnapshot {
  const factory ActiveProfileSnapshot({
    required String activeProfileId,
    required DateTime activatedAt,
  }) = _ActiveProfileSnapshot;

  factory ActiveProfileSnapshot.fromJson(Map<String, dynamic> json) =>
      _$ActiveProfileSnapshotFromJson(json);
}
