import 'package:flutter/material.dart';

import '../../../../core/ui/app_colors.dart';
import '../../../../core/ui/app_radii.dart';
import '../../../../core/ui/app_spacing.dart';
import '../../../../core/ui/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/env_profile.dart';

enum EnvProfileCardAction { edit, delete, rollback }

class EnvProfileCard extends StatelessWidget {
  const EnvProfileCard({
    super.key,
    required this.profile,
    required this.onEdit,
    required this.onDelete,
    this.isActive = false,
    this.isSwitching = false,
    this.onActivate,
    this.onRollback,
  });

  final EnvProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  final bool isActive;
  final bool isSwitching;

  final VoidCallback? onActivate;
  final VoidCallback? onRollback;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      color: isActive ? AppColors.surfaceElevated : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: SizedBox(
          width: 2,
          height: 40,
          child: isActive
              ? Container(
                  key: const Key('active-indicator'),
                  decoration: const BoxDecoration(color: AppColors.accent),
                )
              : null,
        ),
        title: Row(
          children: [
            Flexible(child: Text(profile.name, style: AppTypography.title)),
            if (isActive) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                key: const Key('active-badge'),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  l10n.cardActive,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontFamily: AppTypography.sans,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            l10n.cardSummary(
              profile.hostsEntries.length,
              profile.envVars.length,
              _formatTimestamp(profile.updatedAt),
            ),
            style: AppTypography.caption,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              key: const Key('activate-button'),
              onPressed: isActive || isSwitching || onActivate == null
                  ? null
                  : onActivate,
              child: Text(isActive ? l10n.actionActive : l10n.actionActivate),
            ),
            PopupMenuButton<EnvProfileCardAction>(
              itemBuilder: (_) => [
                if (isActive)
                  PopupMenuItem<EnvProfileCardAction>(
                    value: EnvProfileCardAction.rollback,
                    child: Text(l10n.actionRollback),
                  ),
                PopupMenuItem<EnvProfileCardAction>(
                  value: EnvProfileCardAction.edit,
                  child: Text(l10n.actionEdit),
                ),
                PopupMenuItem<EnvProfileCardAction>(
                  value: EnvProfileCardAction.delete,
                  child: Text(l10n.actionDelete),
                ),
              ],
              onSelected: (action) {
                switch (action) {
                  case EnvProfileCardAction.edit:
                    onEdit();
                  case EnvProfileCardAction.delete:
                    onDelete();
                  case EnvProfileCardAction.rollback:
                    onRollback?.call();
                }
              },
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }

  static String _formatTimestamp(DateTime t) {
    final local = t.toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${pad(local.month)}-${pad(local.day)} '
        '${pad(local.hour)}:${pad(local.minute)}';
  }
}
