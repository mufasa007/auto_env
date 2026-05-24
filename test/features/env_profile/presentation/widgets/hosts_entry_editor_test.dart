import 'package:auto_env/features/env_profile/domain/entities/hosts_entry.dart';
import 'package:auto_env/features/env_profile/presentation/widgets/hosts_entry_editor.dart';
import 'package:auto_env/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  required List<HostsEntry> entries,
  required ValueChanged<List<HostsEntry>> onChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: HostsEntryEditor(
              entries: entries,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts in Rows mode and shows the add button', (tester) async {
    await _pump(
      tester,
      entries: const [HostsEntry(ip: '127.0.0.1', hostname: 'api.local')],
      onChanged: (_) {},
    );
    expect(find.byKey(const Key('hosts-add-button')), findsOneWidget);
    expect(find.byKey(const Key('hosts-text-field')), findsNothing);
  });

  testWidgets('toggling to Text mode serializes current rows into the field',
      (tester) async {
    await _pump(
      tester,
      entries: const [
        HostsEntry(ip: '10.0.0.1', hostname: 'staging.local'),
      ],
      onChanged: (_) {},
    );

    await tester.tap(find.text('Text'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const Key('hosts-text-field')),
    );
    expect(field.controller!.text, '10.0.0.1 staging.local\n');
  });

  testWidgets('valid text mode edits propagate parsed entries via onChanged',
      (tester) async {
    List<HostsEntry>? received;
    await _pump(
      tester,
      entries: const [],
      onChanged: (next) => received = next,
    );

    await tester.tap(find.text('Text'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('hosts-text-field')),
      '192.168.1.1 router.lan\n# 10.0.0.5 staging.local\n',
    );
    await tester.pumpAndSettle();

    expect(received, [
      const HostsEntry(ip: '192.168.1.1', hostname: 'router.lan'),
      const HostsEntry(
        ip: '10.0.0.5',
        hostname: 'staging.local',
        enabled: false,
      ),
    ]);
  });

  testWidgets('invalid text shows inline error and does NOT propagate',
      (tester) async {
    List<HostsEntry>? received;
    await _pump(
      tester,
      entries: const [
        HostsEntry(ip: '127.0.0.1', hostname: 'api.local'),
      ],
      onChanged: (next) => received = next,
    );
    received = null; // reset capture

    await tester.tap(find.text('Text'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('hosts-text-field')),
      'this is not a hosts entry\n',
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Line 1:'), findsOneWidget);
    expect(received, isNull,
        reason: 'parse failure should not push stale data upstream');
  });
}
