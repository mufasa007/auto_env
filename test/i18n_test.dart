import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards against missing-translation regressions: every translation key
/// present in `app_en.arb` must also be present (with a non-empty value) in
/// every other locale arb file, and vice versa. ARB meta keys (those
/// starting with `@`) are ignored.
void main() {
  final l10nDir = Directory('lib/l10n');

  test('every locale arb has the same string keys as app_en.arb', () {
    final en = _readArbKeys(File('${l10nDir.path}/app_en.arb'));
    expect(en, isNotEmpty);

    final others = l10nDir
        .listSync()
        .whereType<File>()
        .where(
          (f) =>
              f.path.endsWith('.arb') && !f.path.endsWith('app_en.arb'),
        )
        .toList();
    expect(others, isNotEmpty, reason: 'expected at least one non-en arb');

    for (final f in others) {
      final keys = _readArbKeys(f);
      final missing = en.difference(keys);
      final extra = keys.difference(en);
      expect(missing, isEmpty,
          reason: '${f.path} is missing keys: $missing');
      expect(extra, isEmpty,
          reason: '${f.path} has untranslated extras: $extra');
    }
  });

  test('every translation value is a non-empty string', () {
    for (final f in l10nDir.listSync().whereType<File>()) {
      if (!f.path.endsWith('.arb')) continue;
      final raw = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      for (final entry in raw.entries) {
        if (entry.key.startsWith('@')) continue;
        expect(entry.value, isA<String>(),
            reason: '${f.path} key "${entry.key}" is not a string');
        expect((entry.value as String).trim(), isNotEmpty,
            reason: '${f.path} key "${entry.key}" is empty');
      }
    }
  });
}

Set<String> _readArbKeys(File f) {
  final decoded = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  return decoded.keys.where((k) => !k.startsWith('@')).toSet();
}
