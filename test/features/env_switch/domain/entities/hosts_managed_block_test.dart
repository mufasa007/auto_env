import 'package:auto_env/features/env_profile/domain/entities/hosts_entry.dart';
import 'package:auto_env/features/env_switch/domain/entities/hosts_managed_block.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HostsManagedBlock.render', () {
    test('emits markers around enabled entries', () {
      final block = HostsManagedBlock.render(const [
        HostsEntry(ip: '10.0.0.1', hostname: 'api.local'),
        HostsEntry(ip: '10.0.0.2', hostname: 'db.local'),
      ]);
      expect(
        block,
        '# >>> auto_env managed >>>\n'
        '10.0.0.1 api.local\n'
        '10.0.0.2 db.local\n'
        '# <<< auto_env managed <<<\n',
      );
    });

    test('skips entries with enabled=false', () {
      final block = HostsManagedBlock.render(const [
        HostsEntry(ip: '10.0.0.1', hostname: 'api.local'),
        HostsEntry(ip: '10.0.0.2', hostname: 'db.local', enabled: false),
      ]);
      expect(block, contains('api.local'));
      expect(block, isNot(contains('db.local')));
    });

    test('emits only markers when entries are empty', () {
      final block = HostsManagedBlock.render(const []);
      expect(
        block,
        '# >>> auto_env managed >>>\n# <<< auto_env managed <<<\n',
      );
    });

    test('uses CRLF when requested', () {
      final block = HostsManagedBlock.render(
        const [HostsEntry(ip: '10.0.0.1', hostname: 'api.local')],
        lineEnding: '\r\n',
      );
      expect(
        block,
        '# >>> auto_env managed >>>\r\n'
        '10.0.0.1 api.local\r\n'
        '# <<< auto_env managed <<<\r\n',
      );
    });
  });

  group('HostsManagedBlock.detectLineEnding', () {
    test('returns LF for unix content', () {
      expect(HostsManagedBlock.detectLineEnding('a\nb\n'), '\n');
    });

    test('returns CRLF when first newline is CRLF', () {
      expect(HostsManagedBlock.detectLineEnding('a\r\nb\r\n'), '\r\n');
    });

    test('defaults to LF for content with no newline', () {
      expect(HostsManagedBlock.detectLineEnding('no newline here'), '\n');
    });
  });

  group('HostsManagedBlock.split', () {
    test('returns full content as before when markers are absent', () {
      const raw = '127.0.0.1 localhost\n::1 localhost\n';
      final s = HostsManagedBlock.split(raw);
      expect(s.before, raw);
      expect(s.existingBlock, isNull);
      expect(s.after, isEmpty);
    });

    test('extracts an existing managed block sandwiched between user lines',
        () {
      const raw = '127.0.0.1 localhost\n'
          '# >>> auto_env managed >>>\n'
          '10.0.0.1 api.local\n'
          '# <<< auto_env managed <<<\n'
          '::1 localhost\n';
      final s = HostsManagedBlock.split(raw);
      expect(s.before, '127.0.0.1 localhost\n');
      expect(
        s.existingBlock,
        '# >>> auto_env managed >>>\n'
        '10.0.0.1 api.local\n'
        '# <<< auto_env managed <<<\n',
      );
      expect(s.after, '::1 localhost\n');
    });

    test('treats markerStart without markerEnd as absent block', () {
      const raw = '# >>> auto_env managed >>>\n10.0.0.1 api.local\n';
      final s = HostsManagedBlock.split(raw);
      expect(s.existingBlock, isNull);
      expect(s.before, raw);
      expect(s.after, isEmpty);
    });

    test('preserves CRLF byte-for-byte', () {
      const raw = '127.0.0.1 localhost\r\n'
          '# >>> auto_env managed >>>\r\n'
          '10.0.0.1 api.local\r\n'
          '# <<< auto_env managed <<<\r\n'
          '::1 localhost\r\n';
      final s = HostsManagedBlock.split(raw);
      expect(s.before, '127.0.0.1 localhost\r\n');
      expect(
        s.existingBlock,
        '# >>> auto_env managed >>>\r\n'
        '10.0.0.1 api.local\r\n'
        '# <<< auto_env managed <<<\r\n',
      );
      expect(s.after, '::1 localhost\r\n');
    });

    test('only the first marker pair is treated as managed block', () {
      const raw = '# >>> auto_env managed >>>\n'
          '10.0.0.1 api.local\n'
          '# <<< auto_env managed <<<\n'
          '# >>> auto_env managed >>>\n'
          'duplicate\n'
          '# <<< auto_env managed <<<\n';
      final s = HostsManagedBlock.split(raw);
      expect(s.before, isEmpty);
      expect(
        s.existingBlock,
        '# >>> auto_env managed >>>\n'
        '10.0.0.1 api.local\n'
        '# <<< auto_env managed <<<\n',
      );
      expect(
        s.after,
        '# >>> auto_env managed >>>\n'
        'duplicate\n'
        '# <<< auto_env managed <<<\n',
      );
    });

    test('handles missing trailing newline at end of file', () {
      const raw = '127.0.0.1 localhost';
      final s = HostsManagedBlock.split(raw);
      expect(s.before, '127.0.0.1 localhost');
      expect(s.existingBlock, isNull);
      expect(s.after, isEmpty);
    });

    test('three pieces concatenated equal the original input', () {
      const raw = 'a\n'
          '# >>> auto_env managed >>>\n'
          'b\n'
          '# <<< auto_env managed <<<\n'
          'c\n';
      final s = HostsManagedBlock.split(raw);
      expect('${s.before}${s.existingBlock ?? ''}${s.after}', raw);
    });
  });

  group('HostsManagedBlock.mergeIntoHosts', () {
    const newBlock = '# >>> auto_env managed >>>\n'
        '10.0.0.1 api.local\n'
        '# <<< auto_env managed <<<\n';

    test('appends new block when none exists', () {
      const raw = '127.0.0.1 localhost\n';
      final merged = HostsManagedBlock.mergeIntoHosts(raw, newBlock);
      expect(merged, '$raw$newBlock');
    });

    test('replaces an existing managed block, keeping outside lines intact',
        () {
      const raw = '127.0.0.1 localhost\n'
          '# >>> auto_env managed >>>\n'
          'old\n'
          '# <<< auto_env managed <<<\n'
          '::1 localhost\n';
      final merged = HostsManagedBlock.mergeIntoHosts(raw, newBlock);
      expect(
        merged,
        '127.0.0.1 localhost\n'
        '# >>> auto_env managed >>>\n'
        '10.0.0.1 api.local\n'
        '# <<< auto_env managed <<<\n'
        '::1 localhost\n',
      );
    });

    test('repeated merges leave outside-block content byte-identical', () {
      const original = '127.0.0.1 localhost\n::1 localhost\n';
      const blockA = '# >>> auto_env managed >>>\n'
          '10.0.0.1 api.local\n'
          '# <<< auto_env managed <<<\n';
      const blockB = '# >>> auto_env managed >>>\n'
          '10.0.0.2 db.local\n'
          '# <<< auto_env managed <<<\n';
      var current = HostsManagedBlock.mergeIntoHosts(original, blockA);
      current = HostsManagedBlock.mergeIntoHosts(current, blockB);
      current = HostsManagedBlock.mergeIntoHosts(current, blockA);
      final s = HostsManagedBlock.split(current);
      expect('${s.before}${s.after}', original);
    });

    test('inserts a CRLF separator when appending to a CRLF file lacking trailing newline',
        () {
      const raw = '127.0.0.1 localhost\r\n::1 localhost';
      const newBlockCrlf = '# >>> auto_env managed >>>\r\n'
          '10.0.0.1 api.local\r\n'
          '# <<< auto_env managed <<<\r\n';
      final merged = HostsManagedBlock.mergeIntoHosts(raw, newBlockCrlf);
      expect(merged, '$raw\r\n$newBlockCrlf');
    });

    test('handles an empty starting file', () {
      final merged = HostsManagedBlock.mergeIntoHosts('', newBlock);
      expect(merged, newBlock);
    });
  });
}
