import 'package:flutter/material.dart';

import '../../../../core/ui/app_colors.dart';
import '../../../../core/ui/app_spacing.dart';
import '../../../../core/ui/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/exceptions/text_parse_exception.dart';
import '../../domain/services/env_var_text_codec.dart';

typedef EnvVarRow = ({String key, String value});

enum _Mode { rows, text }

class EnvVarEditor extends StatefulWidget {
  const EnvVarEditor({
    super.key,
    required this.entries,
    required this.onChanged,
  });

  final List<EnvVarRow> entries;
  final ValueChanged<List<EnvVarRow>> onChanged;

  @override
  State<EnvVarEditor> createState() => _EnvVarEditorState();
}

class _EnvVarEditorState extends State<EnvVarEditor> {
  _Mode _mode = _Mode.rows;
  late final TextEditingController _text =
      TextEditingController(text: EnvVarTextCodec.serialize(widget.entries));
  EnvVarTextParseException? _parseError;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _updateAt(int i, EnvVarRow next) {
    final list = [...widget.entries];
    list[i] = next;
    widget.onChanged(list);
  }

  void _removeAt(int i) {
    final list = [...widget.entries]..removeAt(i);
    widget.onChanged(list);
  }

  void _addRow() {
    widget.onChanged([...widget.entries, (key: '', value: '')]);
  }

  void _switchMode(_Mode next) {
    if (next == _mode) return;
    if (next == _Mode.text) {
      _text.text = EnvVarTextCodec.serialize(widget.entries);
      _parseError = null;
    }
    setState(() => _mode = next);
  }

  void _onTextChanged(String raw) {
    try {
      final parsed = EnvVarTextCodec.parse(raw);
      setState(() => _parseError = null);
      widget.onChanged(parsed);
    } on EnvVarTextParseException catch (e) {
      setState(() => _parseError = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: SegmentedButton<_Mode>(
            key: const Key('env-mode-toggle'),
            segments: [
              ButtonSegment(value: _Mode.rows, label: Text(l10n.modeRows)),
              ButtonSegment(value: _Mode.text, label: Text(l10n.modeText)),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => _switchMode(s.first),
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_mode == _Mode.rows) _buildRows(l10n) else _buildText(l10n),
      ],
    );
  }

  Widget _buildRows(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.entries.length; i++)
          _VarRow(
            key: ValueKey('env-row-$i'),
            entry: widget.entries[i],
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
            label: Text(l10n.addVariable),
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

  Widget _buildText(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('env-text-field'),
          controller: _text,
          onChanged: _onTextChanged,
          maxLines: null,
          minLines: 6,
          style: AppTypography.mono,
          decoration: InputDecoration(
            hintText: 'API_BASE=https://api.dev\n# DEBUG=true',
            hintStyle:
                AppTypography.mono.copyWith(color: AppColors.textSecondary),
            isDense: true,
          ),
        ),
        if (_parseError != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.parseLineError(
              _parseError!.lineNumber,
              _parseError!.reason,
            ),
            style: AppTypography.caption.copyWith(color: AppColors.error),
          ),
        ],
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
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _key,
              decoration: InputDecoration(
                labelText: l10n.fieldKey,
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
              decoration: InputDecoration(
                labelText: l10n.fieldValue,
                isDense: true,
              ),
              onChanged: (v) =>
                  widget.onChanged((key: widget.entry.key, value: v)),
            ),
          ),
          IconButton(
            tooltip: l10n.remove,
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
