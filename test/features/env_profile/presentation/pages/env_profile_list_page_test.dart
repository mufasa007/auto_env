import 'dart:async';

import 'package:auto_env/features/env_profile/data/repositories/env_profile_repository.dart';
import 'package:auto_env/features/env_profile/domain/entities/env_profile.dart';
import 'package:auto_env/features/env_profile/domain/entities/hosts_entry.dart';
import 'package:auto_env/features/env_profile/presentation/pages/env_profile_edit_page.dart';
import 'package:auto_env/features/env_profile/presentation/pages/env_profile_list_page.dart';
import 'package:auto_env/features/env_profile/presentation/providers/env_profile_providers.dart';
import 'package:auto_env/features/env_profile/presentation/widgets/env_profile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEnvProfileRepository extends Mock implements EnvProfileRepository {}

EnvProfile _profile(
  String id, {
  String name = 'n',
  List<HostsEntry> hosts = const [],
  Map<String, String> vars = const {},
}) =>
    EnvProfile(
      id: id,
      name: name,
      hostsEntries: hosts,
      envVars: vars,
      createdAt: DateTime.utc(2026, 5, 20),
      updatedAt: DateTime.utc(2026, 5, 20),
    );

Future<void> _pumpListPage(
  WidgetTester tester,
  EnvProfileRepository repo,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        envProfileRepositoryProvider.overrideWith((ref) async => repo),
      ],
      child: const MaterialApp(home: EnvProfileListPage()),
    ),
  );
}

void main() {
  late _MockEnvProfileRepository repo;

  setUpAll(() {
    registerFallbackValue(_profile('_fb_'));
  });

  setUp(() {
    repo = _MockEnvProfileRepository();
  });

  testWidgets('shows progress indicator while loading', (tester) async {
    final completer = Completer<List<EnvProfile>>();
    when(() => repo.list()).thenAnswer((_) => completer.future);

    await _pumpListPage(tester, repo);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(<EnvProfile>[]);
    await tester.pumpAndSettle();
  });

  testWidgets('shows empty hint when no profiles', (tester) async {
    when(() => repo.list()).thenAnswer((_) async => <EnvProfile>[]);

    await _pumpListPage(tester, repo);
    await tester.pumpAndSettle();

    expect(find.textContaining('No profiles'), findsOneWidget);
    expect(find.byType(EnvProfileCard), findsNothing);
  });

  testWidgets('renders a card per profile with metadata', (tester) async {
    when(() => repo.list()).thenAnswer(
      (_) async => [
        _profile(
          'p1',
          name: 'dev',
          hosts: const [HostsEntry(ip: '10.0.0.1', hostname: 'api.local')],
          vars: const {'A': '1', 'B': '2'},
        ),
        _profile('p2', name: 'staging'),
      ],
    );

    await _pumpListPage(tester, repo);
    await tester.pumpAndSettle();

    expect(find.byType(EnvProfileCard), findsNWidgets(2));
    expect(find.text('dev'), findsOneWidget);
    expect(find.text('staging'), findsOneWidget);
    expect(find.textContaining('1 hosts'), findsOneWidget);
    expect(find.textContaining('2 env vars'), findsOneWidget);
  });

  testWidgets('shows error state when repository fails', (tester) async {
    when(() => repo.list()).thenThrow(StateError('disk gone'));

    await _pumpListPage(tester, repo);
    await tester.pumpAndSettle();

    expect(find.textContaining('Failed to load profiles'), findsOneWidget);
  });

  testWidgets('FAB pushes editor in new-profile mode', (tester) async {
    when(() => repo.list()).thenAnswer((_) async => <EnvProfile>[]);

    await _pumpListPage(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(EnvProfileEditPage), findsOneWidget);
    expect(find.text('New profile'), findsOneWidget);
  });

  testWidgets('card menu Edit pushes editor with the selected profile',
      (tester) async {
    when(() => repo.list()).thenAnswer((_) async => [_profile('p1', name: 'dev')]);

    await _pumpListPage(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<EnvProfileCardAction>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit').last);
    await tester.pumpAndSettle();

    expect(find.byType(EnvProfileEditPage), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
  });

  testWidgets('card menu Delete then Confirm triggers repository.delete',
      (tester) async {
    when(() => repo.list()).thenAnswer((_) async => [_profile('p1', name: 'dev')]);
    when(() => repo.delete(any())).thenAnswer((_) async {});

    await _pumpListPage(tester, repo);
    await tester.pumpAndSettle();

    when(() => repo.list()).thenAnswer((_) async => <EnvProfile>[]);

    await tester.tap(find.byType(PopupMenuButton<EnvProfileCardAction>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Delete profile?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete-confirm')));
    await tester.pumpAndSettle();

    verify(() => repo.delete('p1')).called(1);
  });

  testWidgets('card menu Delete then Cancel does not call repository.delete',
      (tester) async {
    when(() => repo.list()).thenAnswer((_) async => [_profile('p1', name: 'dev')]);
    when(() => repo.delete(any())).thenAnswer((_) async {});

    await _pumpListPage(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<EnvProfileCardAction>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('delete-cancel')));
    await tester.pumpAndSettle();

    verifyNever(() => repo.delete(any()));
  });
}
