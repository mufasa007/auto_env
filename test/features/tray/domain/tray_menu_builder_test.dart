import 'package:auto_env/features/env_profile/domain/entities/env_profile.dart';
import 'package:auto_env/features/tray/domain/tray_menu_builder.dart';
import 'package:flutter_test/flutter_test.dart';

EnvProfile _profile(String id, String name) => EnvProfile(
      id: id,
      name: name,
      hostsEntries: const [],
      envVars: const {},
      createdAt: DateTime.utc(2026, 5, 25),
      updatedAt: DateTime.utc(2026, 5, 25),
    );

void main() {
  group('buildTrayMenu', () {
    test('empty profile list shows the no-profiles hint + only quit/show',
        () {
      final items = buildTrayMenu(profiles: const [], activeProfileId: null);

      // header + status + sep + hint + sep + show + quit  = 7 entries
      expect(items.length, 7);
      expect(items[0].label, 'auto_env');
      expect(items[0].disabled, isTrue);
      expect(items[1].label, 'No active profile');
      expect(
        items.where((i) => i.label == 'No profiles — create one in the app'),
        hasLength(1),
      );
      expect(items.where((i) => i.key == 'show'), hasLength(1));
      expect(items.where((i) => i.key == 'quit'), hasLength(1));
      expect(items.where((i) => i.key == 'rollback'), isEmpty);
    });

    test('profiles render as checkboxes with activate:<id> keys', () {
      final items = buildTrayMenu(
        profiles: [_profile('p1', 'dev'), _profile('p2', 'staging')],
        activeProfileId: null,
      );

      final activateItems = items.where((i) => i.type == 'checkbox').toList();
      expect(activateItems.length, 2);
      expect(activateItems[0].key, 'activate:p1');
      expect(activateItems[0].label, 'dev');
      expect(activateItems[0].checked, isFalse);
      expect(activateItems[1].key, 'activate:p2');
      expect(activateItems[1].checked, isFalse);
    });

    test('active profile is checked + status line names it + rollback shown',
        () {
      final items = buildTrayMenu(
        profiles: [_profile('p1', 'dev'), _profile('p2', 'staging')],
        activeProfileId: 'p2',
      );

      expect(items[1].label, 'Active: staging');
      final checked = items.where((i) =>
          i.type == 'checkbox' && (i.checked ?? false)).toList();
      expect(checked, hasLength(1));
      expect(checked.single.key, 'activate:p2');
      expect(items.where((i) => i.key == 'rollback'), hasLength(1));
    });

    test('activeProfileId pointing at a missing profile degrades gracefully',
        () {
      final items = buildTrayMenu(
        profiles: [_profile('p1', 'dev')],
        activeProfileId: 'ghost-id',
      );
      // Status falls back to "No active profile"; rollback is still offered
      // because the persisted active id is non-null even if the profile
      // was deleted.
      expect(items[1].label, 'No active profile');
      expect(items.where((i) => i.key == 'rollback'), hasLength(1));
    });

    test('separators are present in the expected places', () {
      final items = buildTrayMenu(
        profiles: [_profile('p1', 'dev')],
        activeProfileId: 'p1',
      );
      final seps = items.where((i) => i.type == 'separator').toList();
      expect(seps.length, 2);
    });
  });

  group('parseTrayMenuKey', () {
    test('activate:<id> parses to TrayActivate with the id', () {
      final action = parseTrayMenuKey('activate:profile-42');
      expect(action, isA<TrayActivate>());
      expect((action as TrayActivate).profileId, 'profile-42');
    });

    test('rollback / show / quit each map to their action', () {
      expect(parseTrayMenuKey('rollback'), isA<TrayRollback>());
      expect(parseTrayMenuKey('show'), isA<TrayShowWindow>());
      expect(parseTrayMenuKey('quit'), isA<TrayQuit>());
    });

    test('null + unknown keys produce null (no-op)', () {
      expect(parseTrayMenuKey(null), isNull);
      expect(parseTrayMenuKey('???'), isNull);
      expect(parseTrayMenuKey(''), isNull);
    });

    test('exported MenuItem keys all round-trip through parseTrayMenuKey',
        () {
      // Defensive check: every key we put into the tray menu must be
      // parseable back to an action, otherwise a click would silently
      // no-op.
      final items = buildTrayMenu(
        profiles: [_profile('p1', 'dev')],
        activeProfileId: 'p1',
      );
      for (final item in items) {
        if (item.disabled || item.type == 'separator') continue;
        final action = parseTrayMenuKey(item.key);
        expect(action, isNotNull,
            reason: 'key=${item.key} did not round-trip');
      }
    });
  });
}
