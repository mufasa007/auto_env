import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/env_profile.dart';
import '../providers/env_profile_providers.dart';
import '../widgets/env_profile_card.dart';
import 'env_profile_edit_page.dart';

class EnvProfileListPage extends ConsumerWidget {
  const EnvProfileListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(envProfileListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Environments')),
      body: asyncList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load profiles:\n$err',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (profiles) {
          if (profiles.isEmpty) {
            return const Center(
              child: Text('No profiles yet. Tap + to create one.'),
            );
          }
          return ListView.builder(
            itemCount: profiles.length,
            itemBuilder: (_, i) {
              final profile = profiles[i];
              return EnvProfileCard(
                key: ValueKey(profile.id),
                profile: profile,
                onEdit: () => _openEditor(context, profile),
                onDelete: () => _deleteProfile(context, ref, profile),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openEditor(BuildContext context, EnvProfile? profile) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EnvProfileEditPage(profile: profile),
      ),
    );
  }

  Future<void> _deleteProfile(
    BuildContext context,
    WidgetRef ref,
    EnvProfile profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete profile?'),
        content: Text(
          'Delete "${profile.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            key: const Key('delete-cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('delete-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(envProfileListProvider.notifier).delete(profile.id);
  }
}
