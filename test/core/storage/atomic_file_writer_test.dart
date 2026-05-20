import 'dart:io';

import 'package:auto_env/core/storage/atomic_file_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('auto_env_atomic_');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('creates parent directories if missing', () async {
    final target = File('${tempDir.path}/nested/dir/state.json');
    final writer = AtomicFileWriter(file: target);

    await writer.write('hello');

    expect(await target.exists(), isTrue);
    expect(await target.readAsString(), 'hello');
  });

  test('overwrites existing file content', () async {
    final target = File('${tempDir.path}/state.json');
    final writer = AtomicFileWriter(file: target);

    await writer.write('first');
    await writer.write('second');

    expect(await target.readAsString(), 'second');
  });

  test('does not leave a .tmp sibling after success', () async {
    final target = File('${tempDir.path}/state.json');
    final writer = AtomicFileWriter(file: target);

    await writer.write('payload');

    final names = tempDir.listSync().map((e) => e.uri.pathSegments.last);
    expect(names.any((n) => n.endsWith('.tmp')), isFalse);
  });
}
