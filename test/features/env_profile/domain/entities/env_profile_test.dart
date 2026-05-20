import 'package:auto_env/features/env_profile/domain/entities/env_profile.dart';
import 'package:auto_env/features/env_profile/domain/entities/hosts_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixedTime = DateTime.utc(2026, 5, 20, 12, 0);

  group('HostsEntry', () {
    test('defaults enabled to true', () {
      const entry = HostsEntry(ip: '127.0.0.1', hostname: 'localhost');
      expect(entry.enabled, true);
    });

    test('json round-trip preserves data', () {
      const original = HostsEntry(
        ip: '10.0.0.1',
        hostname: 'api.local',
        enabled: false,
      );
      final decoded = HostsEntry.fromJson(original.toJson());
      expect(decoded, equals(original));
    });
  });

  group('EnvProfile', () {
    test('constructs with empty hosts/vars by default', () {
      final profile = EnvProfile(
        id: 'p1',
        name: 'dev',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      expect(profile.hostsEntries, isEmpty);
      expect(profile.envVars, isEmpty);
    });

    test('json round-trip preserves data', () {
      final original = EnvProfile(
        id: 'p1',
        name: 'staging',
        hostsEntries: const [
          HostsEntry(ip: '10.0.0.1', hostname: 'api.local'),
          HostsEntry(ip: '10.0.0.2', hostname: 'db.local', enabled: false),
        ],
        envVars: const {
          'API_URL': 'https://staging.example.com',
          'DEBUG': '1',
        },
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final decoded = EnvProfile.fromJson(original.toJson());
      expect(decoded, equals(original));
    });

    test('copyWith overrides field and produces new instance', () {
      final original = EnvProfile(
        id: 'p1',
        name: 'old',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final updated = original.copyWith(name: 'new');
      expect(updated.name, 'new');
      expect(updated.id, original.id);
      expect(identical(original, updated), isFalse);
    });

    test('value equality holds for identical fields', () {
      final a = EnvProfile(
        id: 'p1',
        name: 'dev',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      final b = EnvProfile(
        id: 'p1',
        name: 'dev',
        createdAt: fixedTime,
        updatedAt: fixedTime,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
