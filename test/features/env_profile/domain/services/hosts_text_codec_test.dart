import 'package:auto_env/features/env_profile/domain/entities/hosts_entry.dart';
import 'package:auto_env/features/env_profile/domain/exceptions/text_parse_exception.dart';
import 'package:auto_env/features/env_profile/domain/services/hosts_text_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HostsTextCodec.parse', () {
    test('plain IP+hostname produces one enabled entry', () {
      final entries = HostsTextCodec.parse('127.0.0.1 api.local\n');
      expect(entries, [
        const HostsEntry(ip: '127.0.0.1', hostname: 'api.local'),
      ]);
    });

    test('multiple hostnames on one IP expand to separate entries', () {
      final entries =
          HostsTextCodec.parse('10.0.0.1 api.local cdn.local\n');
      expect(entries, [
        const HostsEntry(ip: '10.0.0.1', hostname: 'api.local'),
        const HostsEntry(ip: '10.0.0.1', hostname: 'cdn.local'),
      ]);
    });

    test('# IP HOSTNAME parses as a disabled entry', () {
      final entries = HostsTextCodec.parse('# 10.0.0.1 disabled.local\n');
      expect(entries, [
        const HostsEntry(
          ip: '10.0.0.1',
          hostname: 'disabled.local',
          enabled: false,
        ),
      ]);
    });

    test('# followed by non-IP token is treated as user comment + ignored',
        () {
      final entries = HostsTextCodec.parse(
        '# this is a real comment\n'
        '127.0.0.1 api.local\n',
      );
      expect(entries, [
        const HostsEntry(ip: '127.0.0.1', hostname: 'api.local'),
      ]);
    });

    test('blank lines and trailing whitespace are skipped', () {
      final entries = HostsTextCodec.parse(
        '\n  \n127.0.0.1 api.local\n\n',
      );
      expect(entries.length, 1);
      expect(entries.first.hostname, 'api.local');
    });

    test('line with single token throws with line number', () {
      expect(
        () => HostsTextCodec.parse(
          '127.0.0.1 api.local\n'
          'onlytoken\n',
        ),
        throwsA(
          isA<HostsTextParseException>()
              .having((e) => e.lineNumber, 'lineNumber', 2),
        ),
      );
    });

    test('non-IP first token throws', () {
      expect(
        () => HostsTextCodec.parse('definitelyNotIp api.local\n'),
        throwsA(isA<HostsTextParseException>()),
      );
    });

    test('IPv6 colons accepted', () {
      final entries = HostsTextCodec.parse('::1 localhost\n');
      expect(entries, [
        const HostsEntry(ip: '::1', hostname: 'localhost'),
      ]);
    });
  });

  group('HostsTextCodec.serialize', () {
    test('enabled entries emit IP HOSTNAME per line', () {
      final text = HostsTextCodec.serialize(const [
        HostsEntry(ip: '127.0.0.1', hostname: 'api.local'),
        HostsEntry(ip: '10.0.0.1', hostname: 'cdn.local'),
      ]);
      expect(text, '127.0.0.1 api.local\n10.0.0.1 cdn.local\n');
    });

    test('disabled entries get a # prefix', () {
      final text = HostsTextCodec.serialize(const [
        HostsEntry(
          ip: '10.0.0.1',
          hostname: 'staging.local',
          enabled: false,
        ),
      ]);
      expect(text, '# 10.0.0.1 staging.local\n');
    });
  });

  group('round-trip', () {
    test('parse(serialize(entries)) == entries (modulo split)', () {
      const entries = [
        HostsEntry(ip: '127.0.0.1', hostname: 'a.local'),
        HostsEntry(ip: '127.0.0.1', hostname: 'b.local', enabled: false),
        HostsEntry(ip: '::1', hostname: 'ipv6.local'),
      ];
      final reparsed = HostsTextCodec.parse(HostsTextCodec.serialize(entries));
      expect(reparsed, entries);
    });
  });
}
