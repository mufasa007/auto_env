import 'package:flutter/material.dart';

import '../../../../core/ui/app_colors.dart';
import '../../../../core/ui/app_spacing.dart';

typedef EnvVarRow = ({String key, String value});

class EnvVarEditor extends StatelessWidget {
  const EnvVarEditor({
    super.key,
    required this.entries,
    required this.onChanged,
  });

  final List<EnvVarRow> entries;
  final ValueChanged<List<EnvVarRow>> onChanged;

  void _updateAt(int i, EnvVarRow next) {
    final list = [...entries];
    list[i] = next;
    onChanged(list);
  }

  void _removeAt(int i) {
    final list = [...entries]..removeAt(i);
    onChanged(list);
  }

  void _addRow() {
    onChanged([...entries, (key: '', value: '')]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < entries.length; i++)
          _VarRow(
            key: ValueKey('env-row-$i'),
            entry: entries[i],
            onChanged: (next) => _updateAt(i, next),
            onRemove: () => _removeAt(i),
          ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('env-add-button'),
            onPressed: _addRow,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add variable'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VarRow extends StatefulWidget {
  const _VarRow({
    super.key,
    required this.entry,
    required this.onChanged,
    required this.onRemove,
  });

  final EnvVarRow entry;
  final ValueChanged<EnvVarRow> onChanged;
  final VoidCallback onRemove;

  @override
  State<_VarRow> createState() => _VarRowState();
}

class _VarRowState extends State<_VarRow> {
  late final TextEditingController _key = TextEditingController(
    text: widget.entry.key,
  );
  late final TextEditingController _value = TextEditingController(
    text: widget.entry.value,
  );

  @override
  void dispose() {
    _key.dispose();
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _key,
              decoration: const InputDecoration(
                labelText: 'Key',
                isDense: true,
              ),
              onChanged: (v) =>
                  widget.onChanged((key: v, value: widget.entry.value)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _value,
              decoration: const InputDecoration(
                labelText: 'Value',
                isDense: true,
              ),
              onChanged: (v) =>
                  widget.onChanged((key: widget.entry.key, value: v)),
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: widget.onRemove,
            icon: const Icon(Icons.close, size: 16),
            color: AppColors.textSecondary,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
