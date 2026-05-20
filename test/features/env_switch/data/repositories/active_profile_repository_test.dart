import 'dart:io';

import 'package:auto_env/features/env_switch/data/repositories/active_profile_json_repository.dart';
import 'package:auto_env/features/env_switch/domain/entities/active_profile_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late File file;
  late ActiveProfileJsonRepository repo;

  final ts = DateTime.utc(2026, 5, 20, 12);

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('auto_env_active_');
    file = File('${tempDir.path}/active.json');
    repo = ActiveProfileJsonRepository(file: file);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('get returns null when file is missing', () async {
    expect(await repo.get(), isNull);
  });

  test('get returns null when file is blank', () async {
    await file.writeAsString('  \n');
    expect(await repo.get(), isNull);
  });

  test('save then get round-trips the snapshot', () async {
    final snap = ActiveProfileSnapshot(activeProfileId: 'p1', activatedAt: ts);
    await repo.save(snap);
    expect(await repo.get(), snap);
  });

  test('save overwrites previous snapshot', () async {
    await repo.save(ActiveProfileSnapshot(activeProfileId: 'p1', activatedAt: ts));
    await repo.save(ActiveProfileSnapshot(activeProfileId: 'p2', activatedAt: ts));
    final got = await repo.get();
    expect(got?.activeProfileId, 'p2');
  });

  test('clear removes the file', () async {
    await repo.save(ActiveProfileSnapshot(activeProfileId: 'p1', activatedAt: ts));
    await repo.clear();
    expect(await file.exists(), isFalse);
    expect(await repo.get(), isNull);
  });

  test('clear on missing file is a no-op', () async {
    await repo.clear();
    expect(await file.exists(), isFalse);
  });

  test('get returns null on corrupted JSON (does not throw)', () async {
    await file.writeAsString('not json');
    expect(await repo.get(), isNull);
  });

  test('get returns null when root is not an object', () async {
    await file.writeAsString('["array","instead"]');
    expect(await repo.get(), isNull);
  });
}
