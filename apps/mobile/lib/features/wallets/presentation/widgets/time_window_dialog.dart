import 'package:flutter/material.dart';

import '../../domain/time_window.dart';
import '../../domain/time_zones.dart';

/// Picks the days, start, end and time zone of one weekly window.
class TimeWindowDialog extends StatefulWidget {
  const TimeWindowDialog({super.key});

  static Future<TimeWindow?> show(BuildContext context) =>
      showDialog<TimeWindow>(
        context: context,
        builder: (_) => const TimeWindowDialog(),
      );

  @override
  State<TimeWindowDialog> createState() => _TimeWindowDialogState();
}

class _TimeWindowDialogState extends State<TimeWindowDialog> {
  static const _days = [
    (1, 'Mon'),
    (2, 'Tue'),
    (3, 'Wed'),
    (4, 'Thu'),
    (5, 'Fri'),
    (6, 'Sat'),
    (0, 'Sun'),
  ];

  final Set<int> _selected = {1, 2, 3, 4, 5};
  TimeOfDay _start = const TimeOfDay(hour: 10, minute: 30);
  TimeOfDay _end = const TimeOfDay(hour: 11, minute: 0);
  String _zone = timeZones.first;

  int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;
  String _text(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String? get _problem {
    if (_selected.isEmpty) return 'Choose at least one day.';
    if (_minutes(_end) <= _minutes(_start)) {
      return 'The end must be after the start (no windows across midnight).';
    }
    return null;
  }

  Future<void> _pick(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (picked != null) setState(() => start ? _start = picked : _end = picked);
  }

  void _save() => Navigator.pop(
    context,
    TimeWindow(
      daysOfWeek: _selected.toList()..sort(),
      startsAt: _text(_start),
      endsAt: _text(_end),
      timeZone: _zone,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final problem = _problem;
    return AlertDialog(
      title: const Text('When can it unlock?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              children: [
                for (final (day, label) in _days) _dayChip(day, label),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pick(true),
                    child: Text('From ${_text(_start)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pick(false),
                    child: Text('Until ${_text(_end)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _zone,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Time zone'),
              items: [
                for (final zone in timeZones)
                  DropdownMenuItem(value: zone, child: Text(zone)),
              ],
              onChanged: (zone) => setState(() => _zone = zone ?? _zone),
            ),
            if (problem != null) ...[
              const SizedBox(height: 12),
              Text(
                problem,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: problem == null ? _save : null,
          child: const Text('Add'),
        ),
      ],
    );
  }

  Widget _dayChip(int day, String label) => FilterChip(
    label: Text(label),
    selected: _selected.contains(day),
    onSelected: (on) =>
        setState(() => on ? _selected.add(day) : _selected.remove(day)),
  );
}
