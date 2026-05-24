import 'package:auto_env/features/env_profile/domain/entities/env_profile.dart';
import 'package:auto_env/features/tray/domain/tray_menu_builder.dart';
import 'package:auto_env/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
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
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('buildTrayMenu', () {
    test('empty profile list shows the no-profiles hint + only quit/show',
        () {
      final items = buildTrayMenu(
        profiles: const [],
        activeProfileId: null,
        l10n: l10n,
      );

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
        l10n: l10n,
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
        l10n: l10n,
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
        l10n: l10n,
      );
      expect(items[1].label, 'No active profile');
      expect(items.where((i) => i.key == 'rollback'), hasLength(1));
    });

    test('separators are present in the expected places', () {
      final items = buildTrayMenu(
        profiles: [_profile('p1', 'dev')],
        activeProfileId: 'p1',
        l10n: l10n,
      );
      final seps = items.where((i) => i.type == 'separator').toList();
      expect(seps.length, 2);
    });

    test('zh locale produces translated labels', () async {
      final zh = await AppLocalizations.delegate.load(const Locale('zh'));
      final items = buildTrayMenu(
        profiles: [_profile('p1', 'dev')],
        activeProfileId: 'p1',
        l10n: zh,
      );
      expect(items[1].label, '已生效：dev');
      expect(items.where((i) => i.key == 'show').single.label, '显示窗口');
      expect(items.where((i) => i.key == 'quit').single.label, '退出');
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
      final items = buildTrayMenu(
        profiles: [_profile('p1', 'dev')],
        activeProfileId: 'p1',
        l10n: l10n,
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
