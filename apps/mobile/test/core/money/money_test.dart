import 'package:cashe/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseCents', () {
    test('reads whole and decimal amounts without floats', () {
      expect(Money.parseCents('10'), 1000);
      expect(Money.parseCents('10.5'), 1050);
      expect(Money.parseCents('10,05'), 1005);
      expect(Money.parseCents(' 0.01 '), 1);
    });

    test('rejects zero, negatives, extra decimals and junk', () {
      for (final input in ['0', '0.00', '-1', '1.234', 'abc', '', '1.']) {
        expect(Money.parseCents(input), isNull, reason: input);
      }
    });
  });

  test('formats with the currency symbol', () {
    expect(const Money(1050, 'ZAR').format(), 'R10.50');
    expect(const Money(300, 'USD').format(), r'$3.00');
    expect(const Money(-125, 'EUR').format(), '−€1.25');
    expect(const Money(123456789, 'GBP').format(), '£1,234,567.89');
  });
}
