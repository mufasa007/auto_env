import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/process/process_runner.dart';
import '../../../env_profile/presentation/providers/env_profile_providers.dart';
import '../../data/repositories/active_profile_json_repository.dart';
import '../../data/repositories/active_profile_repository.dart';
import '../../data/repositories/last_switch_state_json_repository.dart';
import '../../data/repositories/last_switch_state_repository.dart';
import '../../data/services/hosts_file_path.dart';
import '../../data/writers/env_var_writer.dart';
import '../../data/writers/hosts_writer.dart';
import '../../data/writers/macos_env_var_writer.dart';
import '../../data/writers/macos_hosts_writer.dart';
import '../../data/writers/windows_env_var_writer.dart';
import '../../data/writers/windows_hosts_writer.dart';
import '../../domain/entities/active_profile_snapshot.dart';
import '../../domain/entities/switch_progress.dart';
import '../../domain/entities/switch_result.dart';
import '../notifiers/env_switch_notifier.dart';

/// Shared [ProcessRunner] for every writer in this feature. Overridden in
/// tests so the real OS is never touched.
final processRunnerProvider = Provider<ProcessRunner>(
  (_) => const DefaultProcessRunner(),
);

/// Resolves the platform-specific hosts file path. Tests override this with
/// a temp path to keep `/etc/hosts` safe.
final hostsFilePathProvider = Provider<HostsFilePath>(
  (_) => const HostsFilePath(),
);

/// Resolves the Windows helper executable. Default: `auto_env_helper.exe`
/// next to the running app. Overridable for tests + sideloaded installs.
final windowsHelperExePathProvider = Provider<String>((_) {
  final exeDir = File(Platform.resolvedExecutable).parent.path;
  return '$exeDir${Platform.pathSeparator}auto_env_helper.exe';
});

final hostsWriterProvider = FutureProvider<HostsWriter>((ref) async {
  final runner = ref.watch(processRunnerProvider);
  final hostsPath = ref.watch(hostsFilePathProvider).resolve();
  if (Platform.isWindows) {
    final helper = ref.watch(windowsHelperExePathProvider);
    return WindowsHostsWriter(
      hostsFilePath: hostsPath,
      helperExePath: helper,
      processRunner: runner,
    );
  }
  return MacosHostsWriter(
    hostsFilePath: hostsPath,
    processRunner: runner,
  );
});

final envVarWriterProvider = FutureProvider<EnvVarWriter>((ref) async {
  final runner = ref.watch(processRunnerProvider);
  if (Platform.isWindows) {
    return WindowsEnvVarWriter(processRunner: runner);
  }
  final paths = ref.watch(appPathsProvider);
  final shellFile = await paths.userEnvShellFile();
  if (shellFile == null) {
    throw StateError(
      'userEnvShellFile() returned null on a non-Windows platform — '
      'is HOME set?',
    );
  }
  return MacosEnvVarWriter(
    processRunner: runner,
    shellFile: shellFile,
  );
});

final lastSwitchStateRepositoryProvider =
    FutureProvider<LastSwitchStateRepository>((ref) async {
  final paths = ref.watch(appPathsProvider);
  final file = await paths.lastSwitchStateFile();
  return LastSwitchStateJsonRepository(file: file);
});

final activeProfileRepositoryProvider =
    FutureProvider<ActiveProfileRepository>((ref) async {
  final paths = ref.watch(appPathsProvider);
  final file = await paths.activeProfileFile();
  return ActiveProfileJsonRepository(file: file);
});

/// Current active profile snapshot. Recomputed whenever the notifier
/// invalidates this provider after a successful switch / rollback.
final activeProfileSnapshotProvider =
    FutureProvider<ActiveProfileSnapshot?>((ref) async {
  final repo = await ref.watch(activeProfileRepositoryProvider.future);
  return repo.get();
});

/// Progress for the in-flight switch / rollback. Cleared back to null when
/// the operation fails so the UI can drop any progress dialog.
final switchProgressProvider = StateProvider<SwitchProgress?>((_) => null);

final envSwitchNotifierProvider =
    AsyncNotifierProvider<EnvSwitchNotifier, SwitchResult?>(
  EnvSwitchNotifier.new,
);
