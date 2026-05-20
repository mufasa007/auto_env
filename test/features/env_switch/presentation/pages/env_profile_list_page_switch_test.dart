import 'dart:async';

import 'package:auto_env/features/env_profile/presentation/widgets/env_profile_card.dart';
import 'package:auto_env/features/env_profile/data/repositories/env_profile_repository.dart';
import 'package:auto_env/features/env_profile/domain/entities/env_profile.dart';
import 'package:auto_env/features/env_profile/domain/entities/hosts_entry.dart';
import 'package:auto_env/features/env_profile/presentation/pages/env_profile_list_page.dart';
import 'package:auto_env/features/env_profile/presentation/providers/env_profile_providers.dart';
import 'package:auto_env/features/env_switch/data/repositories/active_profile_repository.dart';
import 'package:auto_env/features/env_switch/data/repositories/last_switch_state_repository.dart';
import 'package:auto_env/features/env_switch/data/writers/env_var_writer.dart';
import 'package:auto_env/features/env_switch/data/writers/hosts_writer.dart';
import 'package:auto_env/features/env_switch/domain/entities/active_profile_snapshot.dart';
import 'package:auto_env/features/env_switch/domain/entities/last_switch_state.dart';
import 'package:auto_env/features/env_switch/domain/exceptions.dart';
import 'package:auto_env/features/env_switch/presentation/providers/env_switch_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEnvProfileRepository extends Mock implements EnvProfileRepository {}

class _MockHostsWriter extends Mock implements HostsWriter {}

class _MockEnvVarWriter extends Mock implements EnvVarWriter {}

class _MockLastSwitchStateRepository extends Mock
    implements LastSwitchStateRepository {}

class _MockActiveProfileRepository extends Mock
    implements ActiveProfileRepository {}

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

void main() {
  late _MockEnvProfileRepository profileRepo;
  late _MockHostsWriter hostsWriter;
  late _MockEnvVarWriter envVarWriter;
  late _MockLastSwitchStateRepository lastStateRepo;
  late _MockActiveProfileRepository activeRepo;

  setUpAll(() {
    registerFallbackValue(
      LastSwitchState(timestamp: DateTime.utc(2026, 5, 20)),
    );
    registerFallbackValue(
      ActiveProfileSnapshot(
        activeProfileId: '_',
        activatedAt: DateTime.utc(2026, 5, 20),
      ),
    );
    registerFallbackValue(<String, String>{});
    registerFallbackValue(<String, String?>{});
    registerFallbackValue(_profile('_fb_'));
  });

  setUp(() {
    profileRepo = _MockEnvProfileRepository();
    hostsWriter = _MockHostsWriter();
    envVarWriter = _MockEnvVarWriter();
    lastStateRepo = _MockLastSwitchStateRepository();
    activeRepo = _MockActiveProfileRepository();

    when(() => lastStateRepo.save(any())).thenAnswer((_) async {});
    when(() => lastStateRepo.clear()).thenAnswer((_) async {});
    when(() => lastStateRepo.get()).thenAnswer((_) async => null);
    when(() => activeRepo.save(any())).thenAnswer((_) async {});
    when(() => activeRepo.clear()).thenAnswer((_) async {});
    when(() => activeRepo.get()).thenAnswer((_) async => null);
    when(() => hostsWriter.readExistingManagedBlock())
        .thenAnswer((_) async => null);
    when(() => hostsWriter.applyManagedBlock(any()))
        .thenAnswer((_) async {});
    when(() => envVarWriter.apply(any(), any())).thenAnswer((_) async {});
  });

  Future<void> pumpListPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envProfileRepositoryProvider.overrideWith((_) async => profileRepo),
          hostsWriterProvider.overrideWith((_) async => hostsWriter),
          envVarWriterProvider.overrideWith((_) async => envVarWriter),
          lastSwitchStateRepositoryProvider
              .overrideWith((_) async => lastStateRepo),
          activeProfileRepositoryProvider
              .overrideWith((_) async => activeRepo),
        ],
        child: const MaterialApp(home: EnvProfileListPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('active profile card shows ACTIVE badge + disabled Activate',
      (tester) async {
    when(() => profileRepo.list()).thenAnswer(
      (_) async => [_profile('pA', name: 'dev'), _profile('pB', name: 'prod')],
    );
    when(() => activeRepo.get()).thenAnswer(
      (_) async => ActiveProfileSnapshot(
        activeProfileId: 'pA',
        activatedAt: DateTime.utc(2026, 5, 20),
      ),
    );

    await pumpListPage(tester);

    expect(find.byKey(const Key('active-badge')), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Activate'), findsOneWidget);
  });

  testWidgets('tapping Activate kicks off switch and shows progress dialog',
      (tester) async {
    final completer = Completer<void>();
    when(() => profileRepo.list())
        .thenAnswer((_) async => [_profile('pA', name: 'dev')]);
    when(() => hostsWriter.applyManagedBlock(any()))
        .thenAnswer((_) => completer.future);

    await pumpListPage(tester);

    await tester.tap(find.byKey(const Key('activate-button')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Switching environment'), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('successful switch shows the post-switch banner with elapsed',
      (tester) async {
    when(() => profileRepo.list())
        .thenAnswer((_) async => [_profile('pA', name: 'dev')]);

    await pumpListPage(tester);

    await tester.tap(find.byKey(const Key('activate-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Switched in'), findsOneWidget);
    expect(find.byKey(const Key('post-switch-rollback')), findsOneWidget);
    expect(find.text('Switching environment'), findsNothing);
  });

  testWidgets('PrivilegeDeniedException renders friendly error + Retry button',
      (tester) async {
    when(() => profileRepo.list())
        .thenAnswer((_) async => [_profile('pA', name: 'dev')]);
    when(() => hostsWriter.applyManagedBlock(any())).thenThrow(
      const PrivilegeDeniedException('user canceled'),
    );

    await pumpListPage(tester);

    await tester.tap(find.byKey(const Key('activate-button')));
    await tester.pumpAndSettle();

    expect(find.text('Switch failed'), findsOneWidget);
    expect(find.textContaining('Administrator privilege'), findsOneWidget);
    expect(find.byKey(const Key('switch-error-retry')), findsOneWidget);
    expect(find.byKey(const Key('switch-error-rollback')), findsOneWidget);
  });

  testWidgets(
      'rollback from active card menu calls notifier.rollback (state path)',
      (tester) async {
    when(() => profileRepo.list()).thenAnswer(
      (_) async => [_profile('pA', name: 'dev')],
    );
    when(() => activeRepo.get()).thenAnswer(
      (_) async => ActiveProfileSnapshot(
        activeProfileId: 'pA',
        activatedAt: DateTime.utc(2026, 5, 20),
      ),
    );
    when(() => lastStateRepo.get()).thenAnswer(
      (_) async => LastSwitchState(
        previousActiveId: null,
        hostsManagedBlock: null,
        envVarsApplied: const {},
        timestamp: DateTime.utc(2026, 5, 20),
      ),
    );

    await pumpListPage(tester);

    await tester.tap(find.byType(PopupMenuButton<EnvProfileCardAction>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rollback'));
    await tester.pumpAndSettle();

    verify(() => hostsWriter.applyManagedBlock(any())).called(1);
    verify(() => activeRepo.clear()).called(1);
  });
}
