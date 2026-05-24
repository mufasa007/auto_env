import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/app_colors.dart';
import '../../../../core/ui/app_radii.dart';
import '../../../../core/ui/app_spacing.dart';
import '../../../../core/ui/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/switch_result.dart';
import '../providers/env_switch_providers.dart';

/// Builds the post-switch banner. Returned as a [MaterialBanner] so it can be
/// passed directly to [ScaffoldMessengerState.showMaterialBanner].
MaterialBanner buildPostSwitchBanner({
  required BuildContext context,
  required WidgetRef ref,
  required SwitchResult result,
}) {
  final l10n = AppLocalizations.of(context)!;
  final seconds = (result.elapsed.inMilliseconds / 1000).toStringAsFixed(2);
  return MaterialBanner(
    backgroundColor: AppColors.surfaceElevated,
    elevation: 0,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm,
    ),
    leadingPadding: const EdgeInsets.only(right: AppSpacing.md),
    dividerColor: AppColors.border,
    content: Text(
      l10n.switchedInBanner(seconds),
      style: AppTypography.body,
    ),
    leading: Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.check_rounded,
        size: 16,
        color: AppColors.success,
      ),
    ),
    actions: [
      TextButton(
        key: const Key('post-switch-rollback'),
        onPressed: () async {
          ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
          await ref.read(envSwitchNotifierProvider.notifier).rollback();
        },
        child: Text(l10n.actionRollback),
      ),
      TextButton(
        key: const Key('post-switch-dismiss'),
        onPressed: () =>
            ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
        child: Text(l10n.dismiss),
      ),
    ],
  );
}
