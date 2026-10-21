import 'package:flutter/material.dart';

import '../money/money.dart';

/// What the keypad has typed, shown big ("R12.50"). Keeps a trailing point
/// ("R12.") so the display matches what was pressed.
class AmountDisplay extends StatelessWidget {
  const AmountDisplay({
    super.key,
    required this.typed,
    required this.currency,
    this.size = 48,
  });

  final String typed;
  final String currency;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cents = Money.parseCents(typed);
    final symbol = Money(
      0,
      currency,
    ).format().replaceAll(RegExp(r'[\d.,]'), '');
    final text = cents == null || typed.endsWith('.')
        ? '$symbol$typed'
        : Money(cents, currency).format();
    return Text(
      text,
      key: const Key('amount-display'),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.4,
      ),
    );
  }
}
