import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/app_colors.dart';
import '../../../../core/ui/app_radii.dart';
import '../../../../core/ui/app_spacing.dart';
import '../../../../core/ui/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
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
                      ? AppLocalizations.of(context)!.switchTitleFailed
                      : AppLocalizations.of(context)!.switchTitleRunning,
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
                        child: Text(AppLocalizations.of(context)!.dismiss),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      OutlinedButton(
                        key: const Key('switch-error-rollback'),
                        onPressed: () {
                          ref
                              .read(envSwitchNotifierProvider.notifier)
                              .rollback();
                        },
                        child:
                            Text(AppLocalizations.of(context)!.actionRollback),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ElevatedButton(
                        key: const Key('switch-error-retry'),
                        onPressed: () {
                          ref
                              .read(envSwitchNotifierProvider.notifier)
                              .activate(profileId);
                        },
                        child: Text(AppLocalizations.of(context)!.retry),
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
          _labelFor(context, stage),
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  static String _labelFor(BuildContext context, SwitchStage stage) {
    final l10n = AppLocalizations.of(context)!;
    switch (stage) {
      case SwitchStage.requestingPrivilege:
        return l10n.stageRequestingPrivilege;
      case SwitchStage.writingHosts:
        return l10n.stageWritingHosts;
      case SwitchStage.writingEnvVars:
        return l10n.stageWritingEnvVars;
      case SwitchStage.flushingDns:
        return l10n.stageFlushingDns;
      case SwitchStage.done:
        return l10n.stageDone;
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
          _friendly(context, error),
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

  static String _friendly(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    final name = error.runtimeType.toString();
    final message = error is Exception ? error.toString() : '$error';
    switch (name) {
      case 'PrivilegeDeniedException':
        if (message.contains('password was incorrect')) {
          return l10n.errorPrivilegePasswordWrong;
        }
        if (message.contains('not authorized')) {
          return l10n.errorPrivilegeNotAdmin;
        }
        if (message.contains('user canceled')) {
          return l10n.errorPrivilegeUserCanceled;
        }
        return l10n.errorPrivilegeGeneric;
      case 'HostsWriteFailedException':
        return l10n.errorHostsWrite;
      case 'EnvVarWriteFailedException':
        return l10n.errorEnvVarWrite;
      case 'DnsFlushFailedException':
        return l10n.errorDnsFlush;
      case 'PartialFailureException':
        return l10n.errorPartial;
      default:
        return l10n.errorSwitchGeneric;
    }
  }
}
