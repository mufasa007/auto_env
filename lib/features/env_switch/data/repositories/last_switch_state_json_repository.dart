import 'dart:convert';
import 'dart:io';

import '../../../../core/storage/atomic_file_writer.dart';
import '../../domain/entities/last_switch_state.dart';
import 'last_switch_state_repository.dart';

/// Persists [LastSwitchState] to `<appSupport>/auto_env/last_state.json`.
///
/// Corruption returns null (see [ActiveProfileJsonRepository] for the same
/// rationale).
class LastSwitchStateJsonRepository implements LastSwitchStateRepository {
  LastSwitchStateJsonRepository({required this.file})
      : _writer = AtomicFileWriter(file: file);

  final File file;
  final AtomicFileWriter _writer;

  @override
  Future<LastSwitchState?> get() async {
    if (!await file.exists()) return null;
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return LastSwitchState.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(LastSwitchState state) {
    return _writer.write(jsonEncode(state.toJson()));
  }

  @override
  Future<void> clear() async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}
