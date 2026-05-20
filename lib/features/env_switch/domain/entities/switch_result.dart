import 'package:freezed_annotation/freezed_annotation.dart';

import 'switch_progress.dart';

part 'switch_result.freezed.dart';

@freezed
class SwitchResult with _$SwitchResult {
  const factory SwitchResult({
    required String profileId,
    required Duration elapsed,
    @Default(<SwitchStage>[]) List<SwitchStage> stages,
  }) = _SwitchResult;
}
