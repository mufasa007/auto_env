import 'package:auto_env/features/env_profile/data/repositories/env_profile_repository.dart';
import 'package:auto_env/features/env_profile/domain/entities/env_profile.dart';
import 'package:auto_env/features/env_profile/presentation/providers/env_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockEnvProfileRepository extends Mock implements EnvProfileRepository {}

EnvProfile _profile(String id, {String name = 'n'}) => EnvProfile(
      id: id,
      name: name,
      createdAt: DateTime.utc(2026, 5, 20),
      updatedAt: DateTime.utc(2026, 5, 20),
    );

void main() {
  late _MockEnvProfileRepository repo;

  setUpAll(() {
    registerFallbackValue(_profile('_fb_'));
  });

  setUp(() {
    repo = _MockEnvProfileRepository();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        envProfileRepositoryProvider.overrideWith((ref) async => repo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('envProfileListProvider.build', () {
    test('loads list from repository', () async {
      when(() => repo.list()).thenAnswer((_) async => [_profile('p1')]);

      final container = makeContainer();
      final list = await container.read(envProfileListProvider.future);

      expect(list.map((p) => p.id), ['p1']);
      verify(() => repo.list()).called(1);
    });

    test('load failure becomes AsyncError', () async {
      when(() => repo.list()).thenThrow(StateError('boom'));

      final container = makeContainer();

      await expectLater(
        container.read(envProfileListProvider.future),
        throwsA(isA<StateError>()),
      );
      expect(
        container.read(envProfileListProvider),
        isA<AsyncError<List<EnvProfile>>>(),
      );
    });
  });

  group('envProfileListProvider.add', () {
    test('saves profile and refreshes list (length +1)', () async {
      final p1 = _profile('p1');
      final p2 = _profile('p2');
      when(() => repo.list()).thenAnswer((_) async => [p1]);
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      await container.read(envProfileListProvider.future);

      when(() => repo.list()).thenAnswer((_) async => [p1, p2]);
      await container.read(envProfileListProvider.notifier).add(p2);

      final list = container.read(envProfileListProvider).requireValue;
      expect(list.map((p) => p.id), ['p1', 'p2']);
      verify(() => repo.save(p2)).called(1);
    });

    test('repository failure surfaces as AsyncError', () async {
      when(() => repo.list()).thenAnswer((_) async => <EnvProfile>[]);
      when(() => repo.save(any())).thenThrow(StateError('save failed'));

      final container = makeContainer();
      await container.read(envProfileListProvider.future);

      await container.read(envProfileListProvider.notifier).add(_profile('p1'));

      expect(
        container.read(envProfileListProvider),
        isA<AsyncError<List<EnvProfile>>>(),
      );
    });
  });

  group('envProfileListProvider.edit', () {
    test('saves edited profile and refreshes list with new content',
        () async {
      final original = _profile('p1', name: 'old');
      final edited = _profile('p1', name: 'new');
      when(() => repo.list()).thenAnswer((_) async => [original]);
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      final before = await container.read(envProfileListProvider.future);

      when(() => repo.list()).thenAnswer((_) async => [edited]);
      await container.read(envProfileListProvider.notifier).edit(edited);

      final after = container.read(envProfileListProvider).requireValue;
      expect(after.single.name, 'new');
      expect(identical(before, after), isFalse);
      verify(() => repo.save(edited)).called(1);
    });
  });

  group('envProfileListProvider.delete', () {
    test('removes profile and refreshes list (length -1)', () async {
      final p1 = _profile('p1');
      final p2 = _profile('p2');
      when(() => repo.list()).thenAnswer((_) async => [p1, p2]);
      when(() => repo.delete(any())).thenAnswer((_) async {});

      final container = makeContainer();
      await container.read(envProfileListProvider.future);

      when(() => repo.list()).thenAnswer((_) async => [p2]);
      await container.read(envProfileListProvider.notifier).delete('p1');

      final list = container.read(envProfileListProvider).requireValue;
      expect(list.map((p) => p.id), ['p2']);
      verify(() => repo.delete('p1')).called(1);
    });
  });
}
