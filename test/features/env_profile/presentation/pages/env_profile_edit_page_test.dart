import 'package:auto_env/features/env_profile/data/repositories/env_profile_repository.dart';
import 'package:auto_env/features/env_profile/domain/entities/env_profile.dart';
import 'package:auto_env/features/env_profile/domain/entities/hosts_entry.dart';
import 'package:auto_env/features/env_profile/presentation/pages/env_profile_edit_page.dart';
import 'package:auto_env/features/env_profile/presentation/providers/env_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEnvProfileRepository extends Mock implements EnvProfileRepository {}

EnvProfile _existing() => EnvProfile(
      id: 'existing-id',
      name: 'old-name',
      hostsEntries: const [
        HostsEntry(ip: '10.0.0.1', hostname: 'api.local'),
      ],
      envVars: const {'API_URL': 'https://old'},
      createdAt: DateTime.utc(2026, 5, 1),
      updatedAt: DateTime.utc(2026, 5, 1),
    );

Future<void> _pump(
  WidgetTester tester,
  EnvProfileRepository repo, {
  EnvProfile? profile,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        envProfileRepositoryProvider.overrideWith((ref) async => repo),
      ],
      child: MaterialApp(home: EnvProfileEditPage(profile: profile)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _MockEnvProfileRepository repo;

  setUpAll(() {
    registerFallbackValue(_existing());
  });

  setUp(() {
    repo = _MockEnvProfileRepository();
    when(() => repo.list()).thenAnswer((_) async => <EnvProfile>[]);
    when(() => repo.save(any())).thenAnswer((_) async {});
  });

  testWidgets('new mode: filling form then saving calls save with new uuid id',
      (tester) async {
    await _pump(tester, repo);

    await tester.enterText(find.byKey(const Key('name-field')), 'dev');

    await tester.tap(find.byKey(const Key('hosts-add-button')));
    await tester.pumpAndSettle();
    final ipField = find.widgetWithText(TextField, 'IP');
    final hostField = find.widgetWithText(TextField, 'Hostname');
    await tester.enterText(ipField, '127.0.0.1');
    await tester.enterText(hostField, 'localhost');

    await tester.tap(find.byKey(const Key('env-add-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Key'), 'API');
    await tester.enterText(find.widgetWithText(TextField, 'Value'), 'X');

    await tester.tap(find.byKey(const Key('save-button')));
    await tester.pumpAndSettle();

    final captured =
        verify(() => repo.save(captureAny())).captured.single as EnvProfile;
    expect(captured.name, 'dev');
    expect(captured.id, isNotEmpty);
    expect(captured.hostsEntries, [
      const HostsEntry(ip: '127.0.0.1', hostname: 'localhost'),
    ]);
    expect(captured.envVars, {'API': 'X'});
  });

  testWidgets('edit mode: pre-populated and saving preserves original id',
      (tester) async {
    final existing = _existing();
    await _pump(tester, repo, profile: existing);

    expect(find.text('old-name'), findsOneWidget);
    expect(find.text('10.0.0.1'), findsOneWidget);
    expect(find.text('api.local'), findsOneWidget);
    expect(find.text('API_URL'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('name-field')), 'new-name');
    await tester.tap(find.byKey(const Key('save-button')));
    await tester.pumpAndSettle();

    final captured =
        verify(() => repo.save(captureAny())).captured.single as EnvProfile;
    expect(captured.id, 'existing-id');
    expect(captured.name, 'new-name');
    expect(captured.createdAt, existing.createdAt);
    expect(captured.updatedAt.isAfter(existing.updatedAt), isTrue);
  });

  testWidgets('empty name shows error and does not call save', (tester) async {
    await _pump(tester, repo);

    await tester.tap(find.byKey(const Key('save-button')));
    await tester.pumpAndSettle();

    expect(find.text('Name cannot be empty'), findsOneWidget);
    verifyNever(() => repo.save(any()));
  });

  testWidgets('removing a hosts row drops it from the saved payload',
      (tester) async {
    final existing = _existing();
    await _pump(tester, repo, profile: existing);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.close).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('save-button')));
    await tester.pumpAndSettle();

    final captured =
        verify(() => repo.save(captureAny())).captured.single as EnvProfile;
    expect(captured.hostsEntries, isEmpty);
  });
}
