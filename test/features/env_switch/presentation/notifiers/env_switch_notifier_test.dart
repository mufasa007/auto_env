import 'package:auto_env/features/env_profile/data/repositories/env_profile_repository.dart';
import 'package:auto_env/features/env_profile/domain/entities/env_profile.dart';
import 'package:auto_env/features/env_profile/domain/entities/hosts_entry.dart';
import 'package:auto_env/features/env_profile/presentation/providers/env_profile_providers.dart';
import 'package:auto_env/features/env_switch/data/repositories/active_profile_repository.dart';
import 'package:auto_env/features/env_switch/data/repositories/last_switch_state_repository.dart';
import 'package:auto_env/features/env_switch/data/writers/env_var_writer.dart';
import 'package:auto_env/features/env_switch/data/writers/hosts_writer.dart';
import 'package:auto_env/features/env_switch/domain/entities/active_profile_snapshot.dart';
import 'package:auto_env/features/env_switch/domain/entities/hosts_managed_block.dart';
import 'package:auto_env/features/env_switch/domain/entities/last_switch_state.dart';
import 'package:auto_env/features/env_switch/domain/entities/switch_progress.dart';
import 'package:auto_env/features/env_switch/domain/entities/switch_result.dart';
import 'package:auto_env/features/env_switch/domain/exceptions.dart';
import 'package:auto_env/features/env_switch/presentation/providers/env_switch_providers.dart';
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
  });

  setUp(() {
    profileRepo = _MockEnvProfileRepository();
    hostsWriter = _MockHostsWriter();
    envVarWriter = _MockEnvVarWriter();
    lastStateRepo = _MockLastSwitchStateRepository();
    activeRepo = _MockActiveProfileRepository();

    when(() => lastStateRepo.save(any())).thenAnswer((_) async {});
    when(() => lastStateRepo.clear()).thenAnswer((_) async {});
    when(() => activeRepo.save(any())).thenAnswer((_) async {});
    when(() => activeRepo.clear()).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        envProfileRepositoryProvider.overrideWith((_) async => profileRepo),
        hostsWriterProvider.overrideWith((_) async => hostsWriter),
        envVarWriterProvider.overrideWith((_) async => envVarWriter),
        lastSwitchStateRepositoryProvider
            .overrideWith((_) async => lastStateRepo),
        activeProfileRepositoryProvider
            .overrideWith((_) async => activeRepo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('EnvSwitchNotifier.activate happy path', () {
    test('runs hosts → envVars → active save in order, returns SwitchResult',
        () async {
      final pA = _profile(
        'pA',
        name: 'dev',
        hosts: const [HostsEntry(ip: '10.0.0.1', hostname: 'api.local')],
        vars: const {'KEY_A': 'va'},
      );
      when(() => profileRepo.list()).thenAnswer((_) async => [pA]);
      when(() => lastStateRepo.get()).thenAnswer((_) async => null);
      when(() => activeRepo.get()).thenAnswer((_) async => null);
      when(() => hostsWriter.readExistingManagedBlock())
          .thenAnswer((_) async => null);
      when(() => hostsWriter.applyManagedBlock(any()))
          .thenAnswer((_) async {});
      when(() => envVarWriter.apply(any(), any()))
          .thenAnswer((_) async {});

      final container = makeContainer();
      await container.read(envSwitchNotifierProvider.notifier).activate('pA');

      final state = container.read(envSwitchNotifierProvider);
      expect(state, isA<AsyncData<SwitchResult?>>());
      final result = state.requireValue!;
      expect(result.profileId, 'pA');
      expect(result.stages, contains(SwitchStage.writingHosts));
      expect(result.stages, contains(SwitchStage.writingEnvVars));
      expect(result.stages, contains(SwitchStage.done));

      verifyInOrder([
        () => lastStateRepo.save(any()),
        () => hostsWriter.applyManagedBlock(
              HostsManagedBlock.render(pA.hostsEntries),
            ),
        () => envVarWriter.apply(pA.envVars, any()),
        () => activeRepo.save(any()),
      ]);
    });

    test('persists LastSwitchState BEFORE writing hosts (crash-safety)',
        () async {
      final pA = _profile('pA');
      when(() => profileRepo.list()).thenAnswer((_) async => [pA]);
      when(() => lastStateRepo.get()).thenAnswer((_) async => null);
      when(() => activeRepo.get()).thenAnswer((_) async => null);
      when(() => hostsWriter.readExistingManagedBlock())
          .thenAnswer((_) async => '# >>> auto_env managed >>>\n'
              '# <<< auto_env managed <<<\n');
      when(() => hostsWriter.applyManagedBlock(any()))
          .thenAnswer((_) async {});
      when(() => envVarWriter.apply(any(), any()))
          .thenAnswer((_) async {});

      final container = makeContainer();
      await container.read(envSwitchNotifierProvider.notifier).activate('pA');

      final captured = verifyInOrder([
        () => lastStateRepo.save(captureAny()),
        () => hostsWriter.applyManagedBlock(any()),
      ]).captured;
      final saved = captured[0].single as LastSwitchState;
      expect(saved.hostsManagedBlock, contains('auto_env managed'));
    });

    test('passes previous active profile envVars as previous to writer',
        () async {
      final pA = _profile('pA', vars: const {'KEY_A': 'va', 'OLD': 'x'});
      final pB = _profile('pB', vars: const {'KEY_B': 'vb'});
      when(() => profileRepo.list()).thenAnswer((_) async => [pA, pB]);
      when(() => lastStateRepo.get()).thenAnswer((_) async => null);
      when(() => activeRepo.get()).thenAnswer(
        (_) async => ActiveProfileSnapshot(
          activeProfileId: 'pA',
          activatedAt: DateTime.utc(2026, 5, 20),
        ),
      );
      when(() => hostsWriter.readExistingManagedBlock())
          .thenAnswer((_) async => null);
      when(() => hostsWriter.applyManagedBlock(any()))
          .thenAnswer((_) async {});
      when(() => envVarWriter.apply(any(), any()))
          .thenAnswer((_) async {});

      final container = makeContainer();
      await container.read(envSwitchNotifierProvider.notifier).activate('pB');

      final invocations =
          verify(() => envVarWriter.apply(captureAny(), captureAny()))
              .captured;
      expect(invocations[0], pB.envVars);
      expect(invocations[1], pA.envVars);
    });
  });

  group('EnvSwitchNotifier.activate errors', () {
    test('hosts writer failure leaves state AsyncError and active.json unwritten',
        () async {
      final pA = _profile('pA');
      when(() => profileRepo.list()).thenAnswer((_) async => [pA]);
      when(() => lastStateRepo.get()).thenAnswer((_) async => null);
      when(() => activeRepo.get()).thenAnswer((_) async => null);
      when(() => hostsWriter.readExistingManagedBlock())
          .thenAnswer((_) async => null);
      when(() => hostsWriter.applyManagedBlock(any())).thenThrow(
        const PrivilegeDeniedException('user canceled'),
      );

      final container = makeContainer();
      await container.read(envSwitchNotifierProvider.notifier).activate('pA');

      final state = container.read(envSwitchNotifierProvider);
      expect(state, isA<AsyncError<SwitchResult?>>());
      expect(state.error, isA<PrivilegeDeniedException>());

      verify(() => lastStateRepo.save(any())).called(1);
      verifyNever(() => envVarWriter.apply(any(), any()));
      verifyNever(() => activeRepo.save(any()));
    });

    test('env var writer failure surfaces typed exception, hosts already written',
        () async {
      final pA = _profile('pA');
      when(() => profileRepo.list()).thenAnswer((_) async => [pA]);
      when(() => lastStateRepo.get()).thenAnswer((_) async => null);
      when(() => activeRepo.get()).thenAnswer((_) async => null);
      when(() => hostsWriter.readExistingManagedBlock())
          .thenAnswer((_) async => null);
      when(() => hostsWriter.applyManagedBlock(any()))
          .thenAnswer((_) async {});
      when(() => envVarWriter.apply(any(), any()))
          .thenThrow(const EnvVarWriteFailedException('launchctl failed'));

      final container = makeContainer();
      await container.read(envSwitchNotifierProvider.notifier).activate('pA');

      final state = container.read(envSwitchNotifierProvider);
      expect(state, isA<AsyncError<SwitchResult?>>());
      expect(state.error, isA<EnvVarWriteFailedException>());
      verifyNever(() => activeRepo.save(any()));
    });

    test('unknown profile id throws HostsWriteFailedException', () async {
      when(() => profileRepo.list()).thenAnswer((_) async => []);

      final container = makeContainer();
      await container
          .read(envSwitchNotifierProvider.notifier)
          .activate('missing');

      final state = container.read(envSwitchNotifierProvider);
      expect(state, isA<AsyncError<SwitchResult?>>());
      expect(state.error, isA<HostsWriteFailedException>());
    });
  });

  group('EnvSwitchNotifier concurrency', () {
    test('second activate is ignored while first is in flight', () async {
      final pA = _profile('pA');
      when(() => profileRepo.list()).thenAnswer((_) async => [pA]);
      when(() => lastStateRepo.get()).thenAnswer((_) async => null);
      when(() => activeRepo.get()).thenAnswer((_) async => null);
      when(() => hostsWriter.readExistingManagedBlock())
          .thenAnswer((_) async => null);
      when(() => hostsWriter.applyManagedBlock(any()))
          .thenAnswer((_) async {});
      when(() => envVarWriter.apply(any(), any()))
          .thenAnswer((_) async {});

      final container = makeContainer();
      final notifier = container.read(envSwitchNotifierProvider.notifier);

      final first = notifier.activate('pA');
      final second = notifier.activate('pA');
      await Future.wait<void>([first, second]);

      verify(() => hostsWriter.applyManagedBlock(any())).called(1);
    });
  });

  group('EnvSwitchNotifier.rollback', () {
    test('restores previous hosts block + previous profile env vars', () async {
      final pA = _profile('pA', vars: const {'KEY_A': 'va'});
      final pB = _profile('pB', vars: const {'KEY_B': 'vb'});
      when(() => profileRepo.list()).thenAnswer((_) async => [pA, pB]);
      when(() => activeRepo.get()).thenAnswer(
        (_) async => ActiveProfileSnapshot(
          activeProfileId: 'pB',
          activatedAt: DateTime.utc(2026, 5, 20),
        ),
      );
      when(() => lastStateRepo.get()).thenAnswer(
        (_) async => LastSwitchState(
          previousActiveId: 'pA',
          hostsManagedBlock: '# >>> auto_env managed >>>\n'
              '10.0.0.1 api.local\n'
              '# <<< auto_env managed <<<\n',
          envVarsApplied: const {'KEY_A': 'va'},
          timestamp: DateTime.utc(2026, 5, 20),
        ),
      );
      when(() => hostsWriter.applyManagedBlock(any()))
          .thenAnswer((_) async {});
      when(() => envVarWriter.apply(any(), any()))
          .thenAnswer((_) async {});

      final container = makeContainer();
      await container.read(envSwitchNotifierProvider.notifier).rollback();

      verify(
        () => hostsWriter.applyManagedBlock(
          '# >>> auto_env managed >>>\n'
          '10.0.0.1 api.local\n'
          '# <<< auto_env managed <<<\n',
        ),
      ).called(1);

      final invocations =
          verify(() => envVarWriter.apply(captureAny(), captureAny()))
              .captured;
      expect(invocations[0], pA.envVars);
      expect(invocations[1], pB.envVars);

      final captured = verify(() => activeRepo.save(captureAny()))
          .captured
          .single as ActiveProfileSnapshot;
      expect(captured.activeProfileId, 'pA');
      verify(() => lastStateRepo.clear()).called(1);
    });

    test('with no previousActiveId clears active.json and writes empty block',
        () async {
      when(() => profileRepo.list()).thenAnswer((_) async => []);
      when(() => activeRepo.get()).thenAnswer((_) async => null);
      when(() => lastStateRepo.get()).thenAnswer(
        (_) async => LastSwitchState(
          previousActiveId: null,
          hostsManagedBlock: null,
          envVarsApplied: const {},
          timestamp: DateTime.utc(2026, 5, 20),
        ),
      );
      when(() => hostsWriter.applyManagedBlock(any()))
          .thenAnswer((_) async {});
      when(() => envVarWriter.apply(any(), any()))
          .thenAnswer((_) async {});

      final container = makeContainer();
      await container.read(envSwitchNotifierProvider.notifier).rollback();

      verify(() => hostsWriter.applyManagedBlock(
            HostsManagedBlock.render(const []),
          )).called(1);
      verify(() => activeRepo.clear()).called(1);
      verifyNever(() => activeRepo.save(any()));
    });

    test('no previous state surfaces HostsWriteFailedException', () async {
      when(() => lastStateRepo.get()).thenAnswer((_) async => null);

      final container = makeContainer();
      await container.read(envSwitchNotifierProvider.notifier).rollback();

      final state = container.read(envSwitchNotifierProvider);
      expect(state, isA<AsyncError<SwitchResult?>>());
      expect(state.error, isA<HostsWriteFailedException>());
    });
  });

  group('progress provider', () {
    test('advances through stages during a successful activate', () async {
      final pA = _profile('pA');
      when(() => profileRepo.list()).thenAnswer((_) async => [pA]);
      when(() => lastStateRepo.get()).thenAnswer((_) async => null);
      when(() => activeRepo.get()).thenAnswer((_) async => null);
      when(() => hostsWriter.readExistingManagedBlock())
          .thenAnswer((_) async => null);
      when(() => hostsWriter.applyManagedBlock(any()))
          .thenAnswer((_) async {});
      when(() => envVarWriter.apply(any(), any()))
          .thenAnswer((_) async {});

      final container = makeContainer();
      await container.read(envSwitchNotifierProvider.notifier).activate('pA');

      final progress = container.read(switchProgressProvider);
      expect(progress?.stage, SwitchStage.done);
      expect(progress?.percent, 1.0);
    });

    test('clears progress to null on error', () async {
      final pA = _profile('pA');
      when(() => profileRepo.list()).thenAnswer((_) async => [pA]);
      when(() => lastStateRepo.get()).thenAnswer((_) async => null);
      when(() => activeRepo.get()).thenAnswer((_) async => null);
      when(() => hostsWriter.readExistingManagedBlock())
          .thenAnswer((_) async => null);
      when(() => hostsWriter.applyManagedBlock(any())).thenThrow(
        const HostsWriteFailedException('cp failed'),
      );

      final container = makeContainer();
      await container.read(envSwitchNotifierProvider.notifier).activate('pA');

      expect(container.read(switchProgressProvider), isNull);
    });
  });
}
