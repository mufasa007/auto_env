import 'package:auto_env/core/async/serial_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SerialQueue', () {
    test('runs actions in submission order regardless of action duration',
        () async {
      final queue = SerialQueue();
      final order = <int>[];
      final futures = <Future<void>>[
        for (var i = 0; i < 5; i++)
          queue.run(() async {
            // earlier submissions sleep longer; without serialization they
            // would complete in reverse order
            await Future<void>.delayed(Duration(milliseconds: (5 - i) * 5));
            order.add(i);
          }),
      ];
      await Future.wait(futures);
      expect(order, [0, 1, 2, 3, 4]);
    });

    test('propagates exceptions to the failing caller', () async {
      final queue = SerialQueue();
      await expectLater(
        queue.run<int>(() async => throw StateError('boom')),
        throwsA(isA<StateError>()),
      );
    });

    test('continues running subsequent actions after a failure', () async {
      final queue = SerialQueue();
      await expectLater(
        queue.run<void>(() async => throw StateError('boom')),
        throwsA(isA<StateError>()),
      );
      final result = await queue.run<int>(() async => 42);
      expect(result, 42);
    });

    test('returns the value produced by the action', () async {
      final queue = SerialQueue();
      final result = await queue.run<String>(() async => 'hi');
      expect(result, 'hi');
    });
  });
}
