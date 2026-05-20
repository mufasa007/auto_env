import 'package:flutter/material.dart';

import '../../domain/entities/hosts_entry.dart';

class HostsEntryEditor extends StatelessWidget {
  const HostsEntryEditor({
    super.key,
    required this.entries,
    required this.onChanged,
  });

  final List<HostsEntry> entries;
  final ValueChanged<List<HostsEntry>> onChanged;

  void _updateAt(int i, HostsEntry next) {
    final list = [...entries];
    list[i] = next;
    onChanged(list);
  }

  void _removeAt(int i) {
    final list = [...entries]..removeAt(i);
    onChanged(list);
  }

  void _addRow() {
    onChanged([
      ...entries,
      const HostsEntry(ip: '', hostname: ''),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < entries.length; i++)
          _HostsRow(
            key: ValueKey('hosts-row-$i'),
            entry: entries[i],
            onChanged: (next) => _updateAt(i, next),
            onRemove: () => _removeAt(i),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('hosts-add-button'),
            onPressed: _addRow,
            icon: const Icon(Icons.add),
            label: const Text('Add host entry'),
          ),
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _ip,
              decoration: const InputDecoration(labelText: 'IP'),
              onChanged: (v) =>
                  widget.onChanged(widget.entry.copyWith(ip: v)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _host,
              decoration: const InputDecoration(labelText: 'Hostname'),
              onChanged: (v) =>
                  widget.onChanged(widget.entry.copyWith(hostname: v)),
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: widget.entry.enabled,
            onChanged: (v) =>
                widget.onChanged(widget.entry.copyWith(enabled: v)),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: widget.onRemove,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
