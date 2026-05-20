import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_paths.dart';
import '../../data/repositories/env_profile_json_repository.dart';
import '../../data/repositories/env_profile_repository.dart';
import '../../domain/entities/env_profile.dart';

final appPathsProvider = Provider<AppPaths>((ref) => const DefaultAppPaths());

final envProfileRepositoryProvider = FutureProvider<EnvProfileRepository>(
  (ref) async {
    final paths = ref.watch(appPathsProvider);
    final file = await paths.envProfilesFile();
    return EnvProfileJsonRepository(file: file);
  },
);

final envProfileListProvider =
    AsyncNotifierProvider<EnvProfileListNotifier, List<EnvProfile>>(
  EnvProfileListNotifier.new,
);

class EnvProfileListNotifier extends AsyncNotifier<List<EnvProfile>> {
  Future<EnvProfileRepository> get _repo =>
      ref.read(envProfileRepositoryProvider.future);

  @override
  Future<List<EnvProfile>> build() async {
    final repo = await _repo;
    return repo.list();
  }

  Future<void> add(EnvProfile profile) => _mutate((repo) => repo.save(profile));

  Future<void> edit(EnvProfile profile) =>
      _mutate((repo) => repo.save(profile));

  Future<void> delete(String id) => _mutate((repo) => repo.delete(id));

  Future<void> _mutate(
    Future<void> Function(EnvProfileRepository repo) action,
  ) async {
    state = await AsyncValue.guard(() async {
      final repo = await _repo;
      await action(repo);
      return repo.list();
    });
  }
}
