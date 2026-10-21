import '../../../core/money/money.dart';

/// How full a pot's ring is and what it's measured against: a goal's target if it
/// has one, otherwise everything ever put in ("R34 of R80 left").
class PotProgress {
  const PotProgress._(this.fraction, this.total, this.label);

  factory PotProgress.of({
    required int balanceCents,
    required int fundedCents,
    int? targetCents,
    required String currency,
  }) {
    if (targetCents != null && targetCents > 0) {
      final target = Money(targetCents, currency);
      return PotProgress._(
        balanceCents / targetCents,
        target,
        'of ${target.format()} goal',
      );
    }
    final funded = Money(fundedCents, currency);
    if (fundedCents <= 0) return PotProgress._(0, funded, 'nothing in yet');
    return PotProgress._(
      balanceCents / fundedCents,
      funded,
      'of ${funded.format()} left',
    );
  }

  final double fraction;
  final Money total;
  final String label;
}
