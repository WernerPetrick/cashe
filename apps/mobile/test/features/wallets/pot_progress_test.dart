import 'package:cashe/features/wallets/domain/pot_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('measures what is left against everything put in', () {
    final progress = PotProgress.of(
      balanceCents: 3400,
      fundedCents: 8000,
      currency: 'ZAR',
    );
    expect(progress.fraction, closeTo(0.425, 0.0001));
    expect(progress.label, 'of R80.00 left');
  });

  test('measures a goal against its target', () {
    final progress = PotProgress.of(
      balanceCents: 120000,
      fundedCents: 120000,
      targetCents: 450000,
      currency: 'ZAR',
    );
    expect(progress.label, 'of R4,500.00 goal');
    expect(progress.fraction, closeTo(0.2667, 0.0001));
  });

  test('an empty pot has an empty ring', () {
    final progress = PotProgress.of(
      balanceCents: 0,
      fundedCents: 0,
      currency: 'USD',
    );
    expect(progress.fraction, 0);
    expect(progress.label, 'nothing in yet');
  });
}
