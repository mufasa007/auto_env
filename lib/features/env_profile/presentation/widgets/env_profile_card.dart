import 'package:flutter/material.dart';

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

  /// Whether this profile is currently the active environment.
  final bool isActive;

  /// True while a switch / rollback is in flight anywhere in the app; used to
  /// disable the Activate button so the user cannot kick off a second switch.
  final bool isSwitching;

  final VoidCallback? onActivate;
  final VoidCallback? onRollback;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: isActive
          ? RoundedRectangleBorder(
              side: BorderSide(color: colorScheme.primary, width: 2),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: ListTile(
        leading: isActive
            ? Container(
                key: const Key('active-indicator'),
                width: 8,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            : const SizedBox(width: 8),
        title: Row(
          children: [
            Flexible(child: Text(profile.name)),
            if (isActive) ...[
              const SizedBox(width: 8),
              Container(
                key: const Key('active-badge'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${profile.hostsEntries.length} hosts · '
          '${profile.envVars.length} env vars · '
          'updated ${_formatTimestamp(profile.updatedAt)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              key: const Key('activate-button'),
              onPressed: isActive || isSwitching || onActivate == null
                  ? null
                  : onActivate,
              child: Text(isActive ? 'Active' : 'Activate'),
            ),
            PopupMenuButton<EnvProfileCardAction>(
              itemBuilder: (_) => [
                if (isActive)
                  const PopupMenuItem<EnvProfileCardAction>(
                    value: EnvProfileCardAction.rollback,
                    child: Text('Rollback'),
                  ),
                const PopupMenuItem<EnvProfileCardAction>(
                  value: EnvProfileCardAction.edit,
                  child: Text('Edit'),
                ),
                const PopupMenuItem<EnvProfileCardAction>(
                  value: EnvProfileCardAction.delete,
                  child: Text('Delete'),
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
