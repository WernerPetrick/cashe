import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/ids/idempotency_key.dart';
import '../../../../core/money/money.dart';
import '../../../../core/widgets/amount_display.dart';
import '../../../../core/widgets/amount_keypad.dart';
import '../../../../core/widgets/cashe_widgets.dart';

/// Stands in for the shop's card machine until real card payments exist
/// (post-hackathon): the "machine" sets the amount, then the tap is simulated.
/// Pops with the amount and an idempotency key for this charge.
class CardMachineSheet extends StatefulWidget {
  const CardMachineSheet({
    super.key,
    required this.currency,
    required this.balanceCents,
  });

  final String currency;
  final int balanceCents;

  static Future<({int cents, String key})?> show(
    BuildContext context, {
    required String currency,
    required int balanceCents,
  }) {
    return showModalBottomSheet<({int cents, String key})>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          CardMachineSheet(currency: currency, balanceCents: balanceCents),
    );
  }

  @override
  State<CardMachineSheet> createState() => _CardMachineSheetState();
}

class _CardMachineSheetState extends State<CardMachineSheet> {
  String _typed = '0';
  final _key = newIdempotencyKey();

  @override
  Widget build(BuildContext context) {
    final cents = Money.parseCents(_typed);
    final over = cents != null && cents > widget.balanceCents;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MonoLabel('Prototype · card machine'),
          const SizedBox(height: 8),
          const Text(
            'The till charges',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          AmountDisplay(typed: _typed, currency: widget.currency, size: 44),
          const SizedBox(height: 6),
          Text(
            over
                ? 'More than the ${Money(widget.balanceCents, widget.currency).format()} in this spot'
                : 'Then the phone is tapped',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: over ? CasheColors.warning : CasheColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          AmountKeypad(
            onKey: (key) =>
                setState(() => _typed = KeypadInput.press(_typed, key)),
            keyHeight: 48,
          ),
          const SizedBox(height: 10),
          FilledButton(
            key: const Key('simulate-tap'),
            onPressed: cents == null || over
                ? null
                : () => Navigator.pop(context, (cents: cents, key: _key)),
            child: Text(
              cents == null
                  ? 'Tap to pay'
                  : 'Tap to pay ${Money(cents, widget.currency).format()}',
            ),
          ),
        ],
      ),
    );
  }
}
