import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../env_switch/domain/entities/switch_progress.dart';
import '../../../env_switch/domain/entities/switch_result.dart';
import '../../../env_switch/presentation/providers/env_switch_providers.dart';
import '../../../env_switch/presentation/widgets/post_switch_banner.dart';
import '../../../env_switch/presentation/widgets/switch_progress_dialog.dart';
import '../../../app_settings/presentation/pages/settings_page.dart';
import '../../domain/entities/env_profile.dart';
import '../providers/env_profile_providers.dart';
import '../widgets/env_profile_card.dart';
import 'env_profile_edit_page.dart';

class EnvProfileListPage extends ConsumerStatefulWidget {
  const EnvProfileListPage({super.key});

  @override
  ConsumerState<EnvProfileListPage> createState() => _EnvProfileListPageState();
}

class _EnvProfileListPageState extends ConsumerState<EnvProfileListPage> {
  bool _dialogVisible = false;
  String? _pendingProfileId;

  @override
  Widget build(BuildContext context) {
    _listenToSwitch();

    final asyncList = ref.watch(envProfileListProvider);
    final asyncActive = ref.watch(activeProfileSnapshotProvider);
    final switchState = ref.watch(envSwitchNotifierProvider);
    final activeId = asyncActive.value?.activeProfileId;
    final isSwitching = switchState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Environments'),
        actions: [
          IconButton(
            key: const Key('open-settings'),
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
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
              final isActive = profile.id == activeId;
              return EnvProfileCard(
                key: ValueKey(profile.id),
                profile: profile,
                isActive: isActive,
                isSwitching: isSwitching,
                onEdit: () => _openEditor(context, profile),
                onDelete: () => _deleteProfile(context, ref, profile),
                onActivate: () => _activate(profile.id),
                onRollback: isActive ? _rollback : null,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, null),
        icon: const Icon(Icons.add),
        label: const Text('New profile'),
      ),
    );
  }

  void _listenToSwitch() {
    // Errors and success: always react. Errors open the dialog so the user
    // sees what went wrong; success shows the banner.
    ref.listen(envSwitchNotifierProvider, (previous, next) {
      if (next.hasError) {
        _showDialog();
        return;
      }
      final result = next.value;
      if (result != null && previous?.value != result) {
        _showSuccessBanner(result);
      }
    });

    // Loading-state UI is driven by stage, not by AsyncLoading itself.
    //
    // While stage is requestingPrivilege/writingHosts, the OS-level auth
    // modal (macOS SecurityAgent / Windows UAC) is the visible UI. Opening
    // our own modal on top of it steals focus and traps the user looking
    // at "Switching environment…" while the password prompt sits hidden
    // underneath — eventually SecurityAgent dismisses on its own and the
    // switch fails with no chance to type a password.
    //
    // We only open the Flutter dialog once stage advances past the
    // privileged write, which on both platforms means the OS prompt has
    // already cleared.
    ref.listen(switchProgressProvider, (previous, next) {
      if (next == null) return;
      final notifierState = ref.read(envSwitchNotifierProvider);
      if (!notifierState.isLoading) return;
      switch (next.stage) {
        case SwitchStage.writingEnvVars:
        case SwitchStage.flushingDns:
        case SwitchStage.done:
          _showDialog();
        case SwitchStage.requestingPrivilege:
        case SwitchStage.writingHosts:
          break;
      }
    });
  }

  void _showDialog() {
    if (_dialogVisible) return;
    _dialogVisible = true;
    final pendingId = _pendingProfileId ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = ref.read(envSwitchNotifierProvider);
      if (!current.isLoading && !current.hasError) {
        _dialogVisible = false;
        return;
      }
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => SwitchProgressDialog(profileId: pendingId),
      ).whenComplete(() => _dialogVisible = false);
    });
  }

  void _showSuccessBanner(SwitchResult result) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(
      buildPostSwitchBanner(context: context, ref: ref, result: result),
    );
  }

  Future<void> _activate(String profileId) async {
    _pendingProfileId = profileId;
    await ref.read(envSwitchNotifierProvider.notifier).activate(profileId);
  }

  Future<void> _rollback() async {
    await ref.read(envSwitchNotifierProvider.notifier).rollback();
  }

  void _openEditor(BuildContext context, EnvProfile? profile) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EnvProfileEditPage(profile: profile),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const SettingsPage(),
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
