import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/switch_result.dart';
import '../providers/env_switch_providers.dart';

/// Builds the post-switch banner. Returned as a [MaterialBanner] so it can be
/// passed directly to [ScaffoldMessengerState.showMaterialBanner].
MaterialBanner buildPostSwitchBanner({
  required BuildContext context,
  required WidgetRef ref,
  required SwitchResult result,
}) {
  final seconds = (result.elapsed.inMilliseconds / 1000).toStringAsFixed(2);
  return MaterialBanner(
    content: Text(
      'Switched in ${seconds}s · running processes need a restart to '
      'see new environment variables.',
    ),
    leading: const Icon(Icons.check_circle_outline),
    actions: [
      TextButton(
        key: const Key('post-switch-rollback'),
        onPressed: () async {
          ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
          await ref.read(envSwitchNotifierProvider.notifier).rollback();
        },
        child: const Text('Rollback'),
      ),
      TextButton(
        key: const Key('post-switch-dismiss'),
        onPressed: () =>
            ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
        child: const Text('Dismiss'),
      ),
    ],
  );
}
