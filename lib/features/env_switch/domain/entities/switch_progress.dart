import 'package:freezed_annotation/freezed_annotation.dart';

part 'switch_progress.freezed.dart';

enum SwitchStage {
  requestingPrivilege,
  writingHosts,
  writingEnvVars,
  flushingDns,
  done,
}

@freezed
class SwitchProgress with _$SwitchProgress {
  const factory SwitchProgress({
    required SwitchStage stage,
    @Default(0.0) double percent,
  }) = _SwitchProgress;
}
