import 'package:cashe/features/claims/domain/claim_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const token = 'Qx3n0Lw2kP9vS8tY1aZ4bC7dE6fG5hJ';

  test('reads the token from a claim link', () {
    expect(ClaimLink.tokenFrom('cashe://claim/$token'), token);
  });

  test('accepts a bare token, with surrounding spaces', () {
    expect(ClaimLink.tokenFrom('  $token\n'), token);
  });

  test('rejects other links and junk', () {
    expect(ClaimLink.tokenFrom('https://example.com/claim/$token'), isNull);
    expect(ClaimLink.tokenFrom('cashe://wallets/$token'), isNull);
    expect(ClaimLink.tokenFrom('hello'), isNull);
  });
}
