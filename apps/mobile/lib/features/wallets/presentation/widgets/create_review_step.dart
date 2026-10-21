import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/money/money.dart';
import '../../../../core/widgets/cashe_widgets.dart';
import '../../../places/domain/place.dart';
import '../../domain/time_window.dart';
import '../../domain/wallet_text.dart';
import 'time_window_dialog.dart';

/// Step 3: review the lock or gift, with its name, times and (for gifts) expiry.
class CreateReviewStep extends StatelessWidget {
  const CreateReviewStep({
    super.key,
    required this.isGift,
    required this.amount,
    required this.place,
    required this.name,
    required this.windows,
    required this.expiresAt,
    required this.saving,
    required this.onName,
    required this.onAddWindow,
    required this.onRemoveWindow,
    required this.onExpiry,
    required this.onConfirm,
  });

  final bool isGift;
  final Money amount;
  final Place place;
  final String name;
  final List<TimeWindow> windows;
  final DateTime? expiresAt;
  final bool saving;
  final ValueChanged<String> onName;
  final ValueChanged<TimeWindow> onAddWindow;
  final ValueChanged<int> onRemoveWindow;
  final ValueChanged<DateTime?> onExpiry;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              const SizedBox(height: 24),
              Text(
                isGift ? 'Review your gift' : 'Review your lock',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 30),
              Center(
                child: RingDial(
                  size: 170,
                  thickness: 14,
                  dotted: true,
                  progress: 1,
                  child: Text(
                    amount.format(),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _details(context),
              const SizedBox(height: 14),
              Text(
                isGift
                    ? 'They can only spend this at ${place.name}. If nobody claims it within 3 days, it comes back to you.'
                    : 'You can only spend this money at ${place.name}.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: CasheColors.muted,
                ),
              ),
            ],
          ),
        ),
        FilledButton(
          onPressed: saving ? null : onConfirm,
          child: Text(
            saving
                ? 'Saving…'
                : (isGift
                      ? 'Send ${amount.format()} gift'
                      : 'Lock ${amount.format()}'),
          ),
        ),
      ],
    );
  }

  Widget _details(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            _Row(
              label: 'Name',
              value: name,
              action: 'Edit',
              onAction: () => _editName(context),
            ),
            _Row(label: 'Unlocks at', value: place.name),
            _Row(
              label: 'Stay',
              value:
                  '${WalletText.dwell(place.dwellSeconds)} within ${place.radiusM} m',
            ),
            _Row(
              label: 'When',
              value: WalletText.windows(windows),
              action: 'Add',
              onAction: () async {
                final window = await TimeWindowDialog.show(context);
                if (window != null) onAddWindow(window);
              },
            ),
            if (windows.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => onRemoveWindow(windows.length - 1),
                  child: const Text('Remove last time'),
                ),
              ),
            if (isGift)
              _Row(
                label: 'Expires',
                value: expiresAt == null
                    ? 'Never'
                    : WalletText.date(expiresAt!),
                action: expiresAt == null ? 'Set' : 'Clear',
                onAction: () =>
                    expiresAt == null ? _pickExpiry(context) : onExpiry(null),
                last: true,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(text: name);
    final edited = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (edited != null && edited.trim().isNotEmpty) onName(edited.trim());
  }

  Future<void> _pickExpiry(BuildContext context) async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (day != null) onExpiry(DateTime(day.year, day.month, day.day, 23, 59));
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.action,
    this.onAction,
    this.last = false,
  });

  final String label;
  final String value;
  final String? action;
  final VoidCallback? onAction;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: CasheColors.border)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: CasheColors.textBody),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}
