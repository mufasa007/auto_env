import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/app_colors.dart';
import '../../../../core/ui/app_radii.dart';
import '../../../../core/ui/app_spacing.dart';
import '../../../../core/ui/app_typography.dart';
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

  static const _stages = <SwitchStage>[
    SwitchStage.requestingPrivilege,
    SwitchStage.writingHosts,
    SwitchStage.writingEnvVars,
    SwitchStage.flushingDns,
  ];

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
      child: Dialog(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.modal),
          side: const BorderSide(color: AppColors.border),
        ),
        child: SizedBox(
          width: 480,
          height: 260,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.hasError
                      ? 'Switch failed'
                      : 'Switching environment',
                  style: AppTypography.title,
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: state.hasError
                      ? _ErrorContent(error: state.error!)
                      : _LoadingContent(progress: progress),
                ),
                if (state.hasError) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        key: const Key('switch-error-dismiss'),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Dismiss'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      OutlinedButton(
                        key: const Key('switch-error-rollback'),
                        onPressed: () {
                          ref
                              .read(envSwitchNotifierProvider.notifier)
                              .rollback();
                        },
                        child: const Text('Rollback'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ElevatedButton(
                        key: const Key('switch-error-retry'),
                        onPressed: () {
                          ref
                              .read(envSwitchNotifierProvider.notifier)
                              .activate(profileId);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
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
    final activeIndex = SwitchProgressDialog._stages.indexOf(stage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            for (var i = 0; i < SwitchProgressDialog._stages.length; i++) ...[
              if (i != 0) const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _StageBar(
                  state: i < activeIndex || stage == SwitchStage.done
                      ? _StageBarState.done
                      : i == activeIndex
                          ? _StageBarState.active
                          : _StageBarState.pending,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          _labelFor(stage),
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
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

enum _StageBarState { pending, active, done }

class _StageBar extends StatelessWidget {
  const _StageBar({required this.state});

  final _StageBarState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _StageBarState.done => AppColors.accent,
      _StageBarState.active => AppColors.accent.withValues(alpha: 0.7),
      _StageBarState.pending => AppColors.border,
    };
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
    );
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
        Text(
          _friendly(error),
          style: AppTypography.body,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$error',
          style: AppTypography.caption,
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
