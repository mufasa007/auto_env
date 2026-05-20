import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/switch_progress.dart';
import '../providers/env_switch_providers.dart';

/// Dialog shown for the duration of an `activate` or `rollback` call.
///
/// Reads [switchProgressProvider] for the current stage; reads
/// [envSwitchNotifierProvider] for the loading/error state so it can swap
/// between a busy view and an error view with Retry / Rollback buttons.
/// Self-dismisses when the operation succeeds.
class SwitchProgressDialog extends ConsumerWidget {
  const SwitchProgressDialog({
    super.key,
    required this.profileId,
  });

  /// id of the profile the user just tried to activate; used to retry.
  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(envSwitchNotifierProvider, (previous, next) {
      if (!next.isLoading && !next.hasError && next.value != null) {
        Navigator.of(context, rootNavigator: true).maybePop();
      }
    });

    final state = ref.watch(envSwitchNotifierProvider);
    final progress = ref.watch(switchProgressProvider);

    if (!state.isLoading && !state.hasError && state.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).maybePop();
        }
      });
    }

    return PopScope(
      canPop: !state.isLoading,
      child: AlertDialog(
        title: Text(state.hasError ? 'Switch failed' : 'Switching environment'),
        content: state.hasError
            ? _ErrorContent(error: state.error!)
            : _LoadingContent(progress: progress),
        actions: state.hasError
            ? [
                TextButton(
                  key: const Key('switch-error-rollback'),
                  onPressed: () {
                    // Don't pop — the dialog watches the notifier and will
                    // rebuild to loading/done UI as rollback progresses, then
                    // self-pop on success. Popping here races
                    // _dialogVisible and can swallow the next show.
                    ref.read(envSwitchNotifierProvider.notifier).rollback();
                  },
                  child: const Text('Rollback'),
                ),
                TextButton(
                  key: const Key('switch-error-retry'),
                  onPressed: () {
                    ref
                        .read(envSwitchNotifierProvider.notifier)
                        .activate(profileId);
                  },
                  child: const Text('Retry'),
                ),
                TextButton(
                  key: const Key('switch-error-dismiss'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Dismiss'),
                ),
              ]
            : null,
      ),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent({required this.progress});

  final SwitchProgress? progress;

  @override
  Widget build(BuildContext context) {
    final stage = progress?.stage ?? SwitchStage.requestingPrivilege;
    final percent = progress?.percent ?? 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_labelFor(stage)),
        const SizedBox(height: 16),
        LinearProgressIndicator(value: percent == 0 ? null : percent),
      ],
    );
  }

  static String _labelFor(SwitchStage stage) {
    switch (stage) {
      case SwitchStage.requestingPrivilege:
        return 'Requesting administrator privilege…';
      case SwitchStage.writingHosts:
        return 'Writing hosts file…';
      case SwitchStage.writingEnvVars:
        return 'Updating environment variables…';
      case SwitchStage.flushingDns:
        return 'Flushing DNS cache…';
      case SwitchStage.done:
        return 'Done';
    }
  }
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_friendly(error)),
        const SizedBox(height: 8),
        Text(
          '$error',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  static String _friendly(Object error) {
    final name = error.runtimeType.toString();
    final message = error is Exception ? error.toString() : '$error';
    switch (name) {
      case 'PrivilegeDeniedException':
        if (message.contains('password was incorrect')) {
          return 'The macOS administrator password was wrong. '
              'Tap Retry and enter the password of an admin user on this '
              'Mac (the one you use to log in).';
        }
        if (message.contains('not authorized')) {
          return 'This account is not a macOS administrator. '
              'Switch to an admin user or grant this account admin rights '
              'in System Settings → Users & Groups.';
        }
        if (message.contains('user canceled')) {
          return 'You canceled the administrator prompt. '
              'Tap Retry and approve it to continue.';
        }
        return 'Administrator authorization failed. '
            'Tap Retry to see the prompt again.';
      case 'HostsWriteFailedException':
        return 'Could not write to the hosts file.';
      case 'EnvVarWriteFailedException':
        return 'Could not update environment variables.';
      case 'DnsFlushFailedException':
        return 'DNS cache flush failed.';
      case 'PartialFailureException':
        return 'The switch partially completed. Consider rolling back.';
      default:
        return 'The switch could not be completed.';
    }
  }
}
