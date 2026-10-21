import 'package:intl/intl.dart';

/// An amount in integer cents in one currency. Formatting and parsing never use
/// floating point.
class Money {
  const Money(this.cents, this.currency);

  final int cents;
  final String currency;

  /// Currencies the API accepts (config/cashe.yml).
  static const currencies = ['ZAR', 'USD', 'EUR', 'GBP'];

  static final _amountPattern = RegExp(r'^\d{1,7}([.,]\d{1,2})?$');

  /// "10.5" or "10,50" → 1050; null if it isn't a positive amount.
  static int? parseCents(String input) {
    final text = input.trim();
    if (!_amountPattern.hasMatch(text)) return null;
    final parts = text.split(RegExp('[.,]'));
    final fraction = parts.length > 1 ? parts[1].padRight(2, '0') : '00';
    final cents = int.parse(parts[0]) * 100 + int.parse(fraction);
    return cents > 0 ? cents : null;
  }

  /// R10.00, $3.50, −€1.25
  String format() {
    final symbol = NumberFormat.simpleCurrency(name: currency).currencySymbol;
    final whole = NumberFormat.decimalPattern('en').format(cents.abs() ~/ 100);
    final fraction = (cents.abs() % 100).toString().padLeft(2, '0');
    return '${cents < 0 ? '−' : ''}$symbol$whole.$fraction';
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.cents == cents && other.currency == currency;

  @override
  int get hashCode => Object.hash(cents, currency);

  @override
  String toString() => format();
}
