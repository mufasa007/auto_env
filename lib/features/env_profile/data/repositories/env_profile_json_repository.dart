import 'dart:convert';
import 'dart:io';

import '../../../../core/async/serial_queue.dart';
import '../../../../core/storage/atomic_file_writer.dart';
import '../../domain/entities/env_profile.dart';
import 'env_profile_repository.dart';

class EnvProfileJsonRepository implements EnvProfileRepository {
  EnvProfileJsonRepository({required this.file})
      : _writer = AtomicFileWriter(file: file);

  final File file;
  final AtomicFileWriter _writer;
  final SerialQueue _queue = SerialQueue();

  @override
  Future<List<EnvProfile>> list() async {
    if (!await file.exists()) return <EnvProfile>[];
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return <EnvProfile>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const EnvProfileCorruptedException(
          'profiles.json root must be a JSON array',
        );
      }
      return decoded
          .map((e) => EnvProfile.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on EnvProfileCorruptedException {
      rethrow;
    } on FormatException catch (e) {
      throw EnvProfileCorruptedException('invalid JSON: ${e.message}');
    } catch (e) {
      throw EnvProfileCorruptedException('invalid schema: $e');
    }
  }

  @override
  Future<EnvProfile?> get(String id) async {
    final all = await list();
    for (final profile in all) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  @override
  Future<void> save(EnvProfile profile) {
    return _queue.run(() async {
      final all = (await list()).toList();
      final idx = all.indexWhere((p) => p.id == profile.id);
      if (idx >= 0) {
        all[idx] = profile;
      } else {
        all.add(profile);
      }
      await _writeAll(all);
    });
  }

  @override
  Future<void> delete(String id) {
    return _queue.run(() async {
      final all = (await list()).toList();
      final before = all.length;
      all.removeWhere((p) => p.id == id);
      if (all.length == before) return;
      await _writeAll(all);
    });
  }

  Future<void> _writeAll(List<EnvProfile> profiles) {
    final payload = jsonEncode(profiles.map((p) => p.toJson()).toList());
    return _writer.write(payload);
  }
}
