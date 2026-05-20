import 'dart:io';

import 'package:auto_env/features/env_switch/data/repositories/last_switch_state_json_repository.dart';
import 'package:auto_env/features/env_switch/domain/entities/last_switch_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late File file;
  late LastSwitchStateJsonRepository repo;

  final ts = DateTime.utc(2026, 5, 20, 12);

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('auto_env_lstate_');
    file = File('${tempDir.path}/last_state.json');
    repo = LastSwitchStateJsonRepository(file: file);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('get returns null when file is missing', () async {
    expect(await repo.get(), isNull);
  });

  test('save then get round-trips including nullable map values', () async {
    final state = LastSwitchState(
      previousActiveId: 'p_prev',
      hostsManagedBlock: '# >>> auto_env managed >>>\nold\n# <<< auto_env managed <<<\n',
      envVarsApplied: const {'API_URL': 'oldVal', 'GONE_VAR': null},
      timestamp: ts,
    );
    await repo.save(state);
    final got = await repo.get();
    expect(got, state);
    expect(got!.envVarsApplied['GONE_VAR'], isNull);
    expect(got.envVarsApplied['API_URL'], 'oldVal');
  });

  test('save with null hostsManagedBlock and empty envVarsApplied', () async {
    final state = LastSwitchState(timestamp: ts);
    await repo.save(state);
    final got = await repo.get();
    expect(got, state);
    expect(got!.previousActiveId, isNull);
    expect(got.hostsManagedBlock, isNull);
    expect(got.envVarsApplied, isEmpty);
  });

  test('clear removes the file', () async {
    await repo.save(LastSwitchState(timestamp: ts));
    await repo.clear();
    expect(await file.exists(), isFalse);
  });

  test('get returns null on corrupted JSON', () async {
    await file.writeAsString('{garbage');
    expect(await repo.get(), isNull);
  });

  test('overwrites previous state', () async {
    await repo.save(LastSwitchState(previousActiveId: 'a', timestamp: ts));
    await repo.save(LastSwitchState(previousActiveId: 'b', timestamp: ts));
    final got = await repo.get();
    expect(got?.previousActiveId, 'b');
  });
}
