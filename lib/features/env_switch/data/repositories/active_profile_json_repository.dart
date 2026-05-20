import 'dart:convert';
import 'dart:io';

import '../../../../core/storage/atomic_file_writer.dart';
import '../../domain/entities/active_profile_snapshot.dart';
import 'active_profile_repository.dart';

/// Persists [ActiveProfileSnapshot] to `<appSupport>/auto_env/active.json`.
///
/// Corruption policy: a malformed file is treated as "no active profile"
/// (returns null) rather than throwing. This is operational state, not
/// primary data — a broken file should not block the app from booting.
class ActiveProfileJsonRepository implements ActiveProfileRepository {
  ActiveProfileJsonRepository({required this.file})
      : _writer = AtomicFileWriter(file: file);

  final File file;
  final AtomicFileWriter _writer;

  @override
  Future<ActiveProfileSnapshot?> get() async {
    if (!await file.exists()) return null;
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return ActiveProfileSnapshot.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(ActiveProfileSnapshot snapshot) {
    return _writer.write(jsonEncode(snapshot.toJson()));
  }

  @override
  Future<void> clear() async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}
