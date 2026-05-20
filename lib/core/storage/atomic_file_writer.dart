import 'dart:io';

/// Writes a file by streaming the payload to `<path>.tmp` and renaming on
/// success, so a crash mid-write cannot leave a half-written destination.
///
/// Concurrent writes are NOT serialized here — wrap calls in a [SerialQueue]
/// when the caller's logic depends on read-modify-write atomicity.
class AtomicFileWriter {
  const AtomicFileWriter({required this.file});

  final File file;

  Future<void> write(String payload) async {
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(payload, flush: true);
    await tmp.rename(file.path);
  }
}
