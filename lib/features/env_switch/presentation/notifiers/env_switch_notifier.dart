import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../env_profile/domain/entities/env_profile.dart';
import '../../../env_profile/presentation/providers/env_profile_providers.dart';
import '../../domain/entities/active_profile_snapshot.dart';
import '../../domain/entities/hosts_managed_block.dart';
import '../../domain/entities/last_switch_state.dart';
import '../../domain/entities/switch_progress.dart';
import '../../domain/entities/switch_result.dart';
import '../../domain/exceptions.dart';
import '../providers/env_switch_providers.dart';

/// Orchestrates a single hosts + env-var switch end-to-end.
///
/// [LastSwitchState] is written BEFORE the system is touched so a crash mid
/// switch still leaves a recoverable trail. Failures surface as [AsyncError]
/// carrying the typed [SwitchException]; rollback is an explicit user action
/// via [rollback], never automatic.
class EnvSwitchNotifier extends AsyncNotifier<SwitchResult?> {
  bool _busy = false;

  @override
  Future<SwitchResult?> build() async => null;

  Future<void> activate(String profileId) async {
    if (_busy) return;
    _busy = true;

    final progress = ref.read(switchProgressProvider.notifier);
    progress.state = const SwitchProgress(
      stage: SwitchStage.requestingPrivilege,
    );

    state = const AsyncLoading();
    state = await AsyncValue.guard<SwitchResult?>(() async {
      try {
        final stopwatch = Stopwatch()..start();
        final stages = <SwitchStage>[SwitchStage.requestingPrivilege];

        final profiles = await ref.read(envProfileListProvider.future);
        final target = _findProfile(profiles, profileId);
        if (target == null) {
          throw HostsWriteFailedException('profile $profileId not found');
        }

        final hostsWriter = await ref.read(hostsWriterProvider.future);
        final envVarWriter = await ref.read(envVarWriterProvider.future);
        final lastStateRepo =
            await ref.read(lastSwitchStateRepositoryProvider.future);
        final activeRepo =
            await ref.read(activeProfileRepositoryProvider.future);

        final currentActive = await activeRepo.get();
        final currentProfile = currentActive == null
            ? null
            : _findProfile(profiles, currentActive.activeProfileId);
        final currentEnvVars =
            currentProfile?.envVars ?? const <String, String>{};
        final previousBlock = await hostsWriter.readExistingManagedBlock();

        await lastStateRepo.save(
          LastSwitchState(
            previousActiveId: currentActive?.activeProfileId,
            hostsManagedBlock: previousBlock,
            envVarsApplied: {
              for (final e in currentEnvVars.entries) e.key: e.value,
            },
            timestamp: DateTime.now().toUtc(),
          ),
        );

        progress.state = const SwitchProgress(
          stage: SwitchStage.writingHosts,
          percent: 0.25,
        );
        stages.add(SwitchStage.writingHosts);
        final newBlock = HostsManagedBlock.render(target.hostsEntries);
        await hostsWriter.applyManagedBlock(newBlock);

        progress.state = const SwitchProgress(
          stage: SwitchStage.writingEnvVars,
          percent: 0.6,
        );
        stages.add(SwitchStage.writingEnvVars);
        await envVarWriter.apply(target.envVars, {
          for (final e in currentEnvVars.entries) e.key: e.value,
        });

        progress.state = const SwitchProgress(
          stage: SwitchStage.flushingDns,
          percent: 0.85,
        );
        stages.add(SwitchStage.flushingDns);

        await activeRepo.save(
          ActiveProfileSnapshot(
            activeProfileId: target.id,
            activatedAt: DateTime.now().toUtc(),
          ),
        );

        ref.invalidate(activeProfileSnapshotProvider);

        stopwatch.stop();
        stages.add(SwitchStage.done);
        progress.state = const SwitchProgress(
          stage: SwitchStage.done,
          percent: 1.0,
        );

        return SwitchResult(
          profileId: target.id,
          elapsed: stopwatch.elapsed,
          stages: stages,
        );
      } finally {
        _busy = false;
      }
    });

    if (state.hasError) {
      progress.state = null;
    }
  }

  Future<void> rollback() async {
    if (_busy) return;
    _busy = true;

    final progress = ref.read(switchProgressProvider.notifier);
    progress.state = const SwitchProgress(
      stage: SwitchStage.requestingPrivilege,
    );

    state = const AsyncLoading();
    state = await AsyncValue.guard<SwitchResult?>(() async {
      try {
        final stopwatch = Stopwatch()..start();
        final stages = <SwitchStage>[SwitchStage.requestingPrivilege];

        final lastStateRepo =
            await ref.read(lastSwitchStateRepositoryProvider.future);
        final activeRepo =
            await ref.read(activeProfileRepositoryProvider.future);

        final last = await lastStateRepo.get();
        if (last == null) {
          throw const HostsWriteFailedException(
            'no previous state to roll back',
          );
        }

        final hostsWriter = await ref.read(hostsWriterProvider.future);
        final envVarWriter = await ref.read(envVarWriterProvider.future);
        final profiles = await ref.read(envProfileListProvider.future);

        final currentActive = await activeRepo.get();
        final currentProfile = currentActive == null
            ? null
            : _findProfile(profiles, currentActive.activeProfileId);
        final currentEnvVars =
            currentProfile?.envVars ?? const <String, String>{};

        final previousProfile = last.previousActiveId == null
            ? null
            : _findProfile(profiles, last.previousActiveId!);
        final restoreEnvVars =
            previousProfile?.envVars ?? const <String, String>{};

        progress.state = const SwitchProgress(
          stage: SwitchStage.writingHosts,
          percent: 0.3,
        );
        stages.add(SwitchStage.writingHosts);
        final restoreBlock =
            last.hostsManagedBlock ?? HostsManagedBlock.render(const []);
        await hostsWriter.applyManagedBlock(restoreBlock);

        progress.state = const SwitchProgress(
          stage: SwitchStage.writingEnvVars,
          percent: 0.7,
        );
        stages.add(SwitchStage.writingEnvVars);
        await envVarWriter.apply(restoreEnvVars, {
          for (final e in currentEnvVars.entries) e.key: e.value,
        });

        if (last.previousActiveId != null) {
          await activeRepo.save(
            ActiveProfileSnapshot(
              activeProfileId: last.previousActiveId!,
              activatedAt: DateTime.now().toUtc(),
            ),
          );
        } else {
          await activeRepo.clear();
        }
        await lastStateRepo.clear();

        ref.invalidate(activeProfileSnapshotProvider);

        stopwatch.stop();
        stages.add(SwitchStage.done);
        progress.state = const SwitchProgress(
          stage: SwitchStage.done,
          percent: 1.0,
        );

        return SwitchResult(
          profileId: last.previousActiveId ?? '',
          elapsed: stopwatch.elapsed,
          stages: stages,
        );
      } finally {
        _busy = false;
      }
    });

    if (state.hasError) {
      progress.state = null;
    }
  }

  static EnvProfile? _findProfile(List<EnvProfile> profiles, String id) {
    for (final p in profiles) {
      if (p.id == id) return p;
    }
    return null;
  }
}
