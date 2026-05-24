import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/ui/app_colors.dart';
import '../../../../core/ui/app_radii.dart';
import '../../../../core/ui/app_spacing.dart';
import '../../../../core/ui/app_typography.dart';
import '../../domain/entities/env_profile.dart';
import '../../domain/entities/hosts_entry.dart';
import '../providers/env_profile_providers.dart';
import '../widgets/env_var_editor.dart';
import '../widgets/hosts_entry_editor.dart';

const _uuid = Uuid();

class EnvProfileEditPage extends ConsumerStatefulWidget {
  const EnvProfileEditPage({super.key, this.profile});

  final EnvProfile? profile;

  @override
  ConsumerState<EnvProfileEditPage> createState() =>
      _EnvProfileEditPageState();
}

class _EnvProfileEditPageState extends ConsumerState<EnvProfileEditPage> {
  late final TextEditingController _nameController;
  late List<HostsEntry> _hostsEntries;
  late List<EnvVarRow> _envVars;
  String? _nameError;
  bool _saving = false;

  bool get _isNew => widget.profile == null;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameController = TextEditingController(text: p?.name ?? '');
    _hostsEntries = List.of(p?.hostsEntries ?? const <HostsEntry>[]);
    _envVars = (p?.envVars ?? const <String, String>{})
        .entries
        .map<EnvVarRow>((e) => (key: e.key, value: e.value))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Name cannot be empty');
      return;
    }
    setState(() {
      _nameError = null;
      _saving = true;
    });

    final original = widget.profile;
    final now = DateTime.now().toUtc();
    final profile = EnvProfile(
      id: original?.id ?? _uuid.v4(),
      name: name,
      hostsEntries: _hostsEntries,
      envVars: {
        for (final r in _envVars) r.key: r.value,
      },
      createdAt: original?.createdAt ?? now,
      updatedAt: now,
    );

    final notifier = ref.read(envProfileListProvider.notifier);
    try {
      if (_isNew) {
        await notifier.add(profile);
      } else {
        await notifier.edit(profile);
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New profile' : 'Edit profile'),
        toolbarHeight: 48,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              children: [
                TextField(
                  key: const Key('name-field'),
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    errorText: _nameError,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _SectionLabel('Hosts entries'),
                const SizedBox(height: AppSpacing.sm),
                HostsEntryEditor(
                  entries: _hostsEntries,
                  onChanged: (next) => setState(() => _hostsEntries = next),
                ),
                const SizedBox(height: AppSpacing.xl),
                _SectionLabel('Environment variables'),
                const SizedBox(height: AppSpacing.sm),
                EnvVarEditor(
                  entries: _envVars,
                  onChanged: (next) => setState(() => _envVars = next),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.bg,
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  key: const Key('cancel-button'),
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: AppSpacing.sm),
                _saving
                    ? const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : ElevatedButton(
                        key: const Key('save-button'),
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadii.field),
                          ),
                        ),
                        child: const Text('Save'),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.caption.copyWith(
        letterSpacing: 0.6,
        color: AppColors.textSecondary,
      ),
    );
  }
}
