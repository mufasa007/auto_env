import 'package:flutter/material.dart';

import '../../../../core/ui/app_colors.dart';
import '../../../../core/ui/app_spacing.dart';
import '../../../../core/ui/app_typography.dart';
import '../../domain/entities/hosts_entry.dart';
import '../../domain/exceptions/text_parse_exception.dart';
import '../../domain/services/hosts_text_codec.dart';

enum _Mode { rows, text }

class HostsEntryEditor extends StatefulWidget {
  const HostsEntryEditor({
    super.key,
    required this.entries,
    required this.onChanged,
  });

  final List<HostsEntry> entries;
  final ValueChanged<List<HostsEntry>> onChanged;

  @override
  State<HostsEntryEditor> createState() => _HostsEntryEditorState();
}

class _HostsEntryEditorState extends State<HostsEntryEditor> {
  _Mode _mode = _Mode.rows;
  late final TextEditingController _text =
      TextEditingController(text: HostsTextCodec.serialize(widget.entries));
  HostsTextParseException? _parseError;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _updateAt(int i, HostsEntry next) {
    final list = [...widget.entries];
    list[i] = next;
    widget.onChanged(list);
  }

  void _removeAt(int i) {
    final list = [...widget.entries]..removeAt(i);
    widget.onChanged(list);
  }

  void _addRow() {
    widget.onChanged([
      ...widget.entries,
      const HostsEntry(ip: '', hostname: ''),
    ]);
  }

  void _switchMode(_Mode next) {
    if (next == _mode) return;
    if (next == _Mode.text) {
      _text.text = HostsTextCodec.serialize(widget.entries);
      _parseError = null;
    }
    setState(() => _mode = next);
  }

  void _onTextChanged(String raw) {
    try {
      final parsed = HostsTextCodec.parse(raw);
      setState(() => _parseError = null);
      widget.onChanged(parsed);
    } on HostsTextParseException catch (e) {
      setState(() => _parseError = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: SegmentedButton<_Mode>(
            key: const Key('hosts-mode-toggle'),
            segments: const [
              ButtonSegment(value: _Mode.rows, label: Text('Rows')),
              ButtonSegment(value: _Mode.text, label: Text('Text')),
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
        if (_mode == _Mode.rows) _buildRows() else _buildText(),
      ],
    );
  }

  Widget _buildRows() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.entries.length; i++)
          _HostsRow(
            key: ValueKey('hosts-row-$i'),
            entry: widget.entries[i],
            onChanged: (next) => _updateAt(i, next),
            onRemove: () => _removeAt(i),
          ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('hosts-add-button'),
            onPressed: _addRow,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add host entry'),
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

  Widget _buildText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('hosts-text-field'),
          controller: _text,
          onChanged: _onTextChanged,
          maxLines: null,
          minLines: 6,
          style: AppTypography.mono,
          decoration: InputDecoration(
            hintText: '127.0.0.1 api.local\n'
                '# 10.0.0.1 disabled.example.com',
            hintStyle:
                AppTypography.mono.copyWith(color: AppColors.textSecondary),
            isDense: true,
          ),
        ),
        if (_parseError != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Line ${_parseError!.lineNumber}: ${_parseError!.reason}',
            style: AppTypography.caption.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

class _HostsRow extends StatefulWidget {
  const _HostsRow({
    super.key,
    required this.entry,
    required this.onChanged,
    required this.onRemove,
  });

  final HostsEntry entry;
  final ValueChanged<HostsEntry> onChanged;
  final VoidCallback onRemove;

  @override
  State<_HostsRow> createState() => _HostsRowState();
}

class _HostsRowState extends State<_HostsRow> {
  late final TextEditingController _ip = TextEditingController(
    text: widget.entry.ip,
  );
  late final TextEditingController _host = TextEditingController(
    text: widget.entry.hostname,
  );

  @override
  void dispose() {
    _ip.dispose();
    _host.dispose();
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
              controller: _ip,
              decoration: const InputDecoration(
                labelText: 'IP',
                isDense: true,
              ),
              onChanged: (v) =>
                  widget.onChanged(widget.entry.copyWith(ip: v)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _host,
              decoration: const InputDecoration(
                labelText: 'Hostname',
                isDense: true,
              ),
              onChanged: (v) =>
                  widget.onChanged(widget.entry.copyWith(hostname: v)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch(
            value: widget.entry.enabled,
            onChanged: (v) =>
                widget.onChanged(widget.entry.copyWith(enabled: v)),
            activeThumbColor: AppColors.accent,
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
