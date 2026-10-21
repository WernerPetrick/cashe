import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// What the keypad has typed so far, e.g. "12.5". Same rules as the design: one
/// decimal point, at most two decimals and six digits.
abstract final class KeypadInput {
  static const keys = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '.',
    '0',
    '⌫',
  ];

  static String press(String current, String key) {
    if (key == '⌫') {
      return current.length > 1
          ? current.substring(0, current.length - 1)
          : '0';
    }
    if (key == '.') return current.contains('.') ? current : '$current.';
    if (current.contains('.') && current.split('.')[1].length >= 2) {
      return current;
    }
    if (current.replaceAll('.', '').length >= 6) return current;
    return current == '0' ? key : current + key;
  }
}

/// The design's 3×4 number pad.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({super.key, required this.onKey, this.keyHeight = 56});

  final ValueChanged<String> onKey;
  final double keyHeight;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3 / (keyHeight / 40),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: [
        for (final key in KeypadInput.keys)
          TextButton(
            key: Key('key-$key'),
            onPressed: () => onKey(key),
            style: TextButton.styleFrom(
              foregroundColor: CasheColors.text,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(key),
          ),
      ],
    );
  }
}
