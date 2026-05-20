import 'package:flutter/material.dart';

import '../../domain/entities/env_profile.dart';

enum EnvProfileCardAction { edit, delete }

class EnvProfileCard extends StatelessWidget {
  const EnvProfileCard({
    super.key,
    required this.profile,
    required this.onEdit,
    required this.onDelete,
  });

  final EnvProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(profile.name),
        subtitle: Text(
          '${profile.hostsEntries.length} hosts · '
          '${profile.envVars.length} env vars · '
          'updated ${_formatTimestamp(profile.updatedAt)}',
        ),
        trailing: PopupMenuButton<EnvProfileCardAction>(
          itemBuilder: (_) => const [
            PopupMenuItem<EnvProfileCardAction>(
              value: EnvProfileCardAction.edit,
              child: Text('Edit'),
            ),
            PopupMenuItem<EnvProfileCardAction>(
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
            }
          },
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
