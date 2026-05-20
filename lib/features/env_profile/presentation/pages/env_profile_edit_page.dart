import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

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
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              key: const Key('save-button'),
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('name-field'),
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              errorText: _nameError,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Hosts entries',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          HostsEntryEditor(
            entries: _hostsEntries,
            onChanged: (next) => setState(() => _hostsEntries = next),
          ),
          const SizedBox(height: 24),
          Text(
            'Environment variables',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          EnvVarEditor(
            entries: _envVars,
            onChanged: (next) => setState(() => _envVars = next),
          ),
        ],
      ),
    );
  }
}
