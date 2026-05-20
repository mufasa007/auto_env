import 'package:freezed_annotation/freezed_annotation.dart';

import 'hosts_entry.dart';

part 'env_profile.freezed.dart';
part 'env_profile.g.dart';

@freezed
class EnvProfile with _$EnvProfile {
  const factory EnvProfile({
    required String id,
    required String name,
    @Default(<HostsEntry>[]) List<HostsEntry> hostsEntries,
    @Default(<String, String>{}) Map<String, String> envVars,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _EnvProfile;

  factory EnvProfile.fromJson(Map<String, dynamic> json) =>
      _$EnvProfileFromJson(json);
}
