import 'dart:io';

import 'package:auto_env/features/env_profile/data/repositories/env_profile_json_repository.dart';
import 'package:auto_env/features/env_profile/data/repositories/env_profile_repository.dart';
import 'package:auto_env/features/env_profile/domain/entities/env_profile.dart';
import 'package:auto_env/features/env_profile/domain/entities/hosts_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late File profilesFile;
  late EnvProfileJsonRepository repo;

  final fixedTime = DateTime.utc(2026, 5, 20, 12);

  EnvProfile sample(String id, {String name = 'dev'}) => EnvProfile(
        id: id,
        name: name,
        hostsEntries: const [
          HostsEntry(ip: '10.0.0.1', hostname: 'api.local'),
        ],
        envVars: const {'API_URL': 'https://example.com'},
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('auto_env_repo_');
    profilesFile = File('${tempDir.path}/profiles.json');
    repo = EnvProfileJsonRepository(file: profilesFile);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('EnvProfileJsonRepository.list', () {
    test('returns empty when file missing', () async {
      expect(await repo.list(), isEmpty);
    });

    test('returns empty when file is blank', () async {
      await profilesFile.writeAsString('   \n');
      expect(await repo.list(), isEmpty);
    });

    test('throws EnvProfileCorruptedException on invalid JSON', () async {
      await profilesFile.writeAsString('{not valid json');
      expect(
        repo.list,
        throwsA(isA<EnvProfileCorruptedException>()),
      );
    });

    test('throws EnvProfileCorruptedException when root is not array',
        () async {
      await profilesFile.writeAsString('{"id":"p1"}');
      expect(
        repo.list,
        throwsA(isA<EnvProfileCorruptedException>()),
      );
    });

    test('throws EnvProfileCorruptedException on schema mismatch', () async {
      await profilesFile.writeAsString('[{"id":"p1"}]');
      expect(
        repo.list,
        throwsA(isA<EnvProfileCorruptedException>()),
      );
    });
  });

  group('EnvProfileJsonRepository.save', () {
    test('persists a new profile so list returns it', () async {
      final profile = sample('p1');
      await repo.save(profile);
      expect(await repo.list(), [profile]);
    });

    test('upserts existing profile in place without duplicating', () async {
      await repo.save(sample('p1', name: 'old'));
      await repo.save(sample('p1', name: 'new'));
      final all = await repo.list();
      expect(all, hasLength(1));
      expect(all.single.name, 'new');
    });

    test('preserves multiple distinct profiles', () async {
      await repo.save(sample('p1'));
      await repo.save(sample('p2', name: 'staging'));
      final ids = (await repo.list()).map((p) => p.id).toList();
      expect(ids, containsAll(<String>['p1', 'p2']));
    });

    test('creates parent directory if missing', () async {
      final nested = File('${tempDir.path}/nested/dir/profiles.json');
      final nestedRepo = EnvProfileJsonRepository(file: nested);
      await nestedRepo.save(sample('p1'));
      expect(await nested.exists(), isTrue);
      expect((await nestedRepo.list()).single.id, 'p1');
    });
  });

  group('EnvProfileJsonRepository.get', () {
    test('returns the profile with matching id', () async {
      await repo.save(sample('p1'));
      final found = await repo.get('p1');
      expect(found?.id, 'p1');
    });

    test('returns null when id is missing', () async {
      await repo.save(sample('p1'));
      expect(await repo.get('missing'), isNull);
    });
  });

  group('EnvProfileJsonRepository.delete', () {
    test('removes the profile so list no longer contains it', () async {
      await repo.save(sample('p1'));
      await repo.save(sample('p2'));
      await repo.delete('p1');
      final ids = (await repo.list()).map((p) => p.id).toList();
      expect(ids, ['p2']);
    });

    test('is a no-op when id is missing', () async {
      await repo.save(sample('p1'));
      await repo.delete('missing');
      expect((await repo.list()).map((p) => p.id), ['p1']);
    });
  });

  group('atomicity', () {
    test('two sequential saves leave the latest write on disk', () async {
      await repo.save(sample('p1', name: 'first'));
      await repo.save(sample('p1', name: 'second'));
      expect((await repo.list()).single.name, 'second');
    });

    test('overlapping saves leave file as valid JSON', () async {
      await Future.wait(<Future<void>>[
        for (var i = 0; i < 5; i++) repo.save(sample('p$i')),
      ]);
      final ids = (await repo.list()).map((p) => p.id).toSet();
      expect(ids, {'p0', 'p1', 'p2', 'p3', 'p4'});
    });
  });
}
