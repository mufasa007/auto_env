import 'package:freezed_annotation/freezed_annotation.dart';

part 'hosts_entry.freezed.dart';
part 'hosts_entry.g.dart';

@freezed
class HostsEntry with _$HostsEntry {
  const factory HostsEntry({
    required String ip,
    required String hostname,
    @Default(true) bool enabled,
  }) = _HostsEntry;

  factory HostsEntry.fromJson(Map<String, dynamic> json) =>
      _$HostsEntryFromJson(json);
}
