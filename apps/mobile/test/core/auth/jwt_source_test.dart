import 'package:cashe/core/auth/jwt_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DateTime now;
  late int minted;
  late JwtSource source;

  setUp(() {
    now = DateTime.utc(2026, 10, 20, 10, 30);
    minted = 0;
    source = JwtSource(mint: () async => 'jwt-${++minted}', now: () => now);
  });

  test('reuses a fresh token', () async {
    expect(await source.token(), 'jwt-1');
    now = now.add(const Duration(minutes: 11));
    expect(await source.token(), 'jwt-1');
  });

  test('mints a new token before the 15-minute expiry', () async {
    await source.token();
    now = now.add(const Duration(minutes: 12));
    expect(await source.token(), 'jwt-2');
  });

  test('mints a new token after invalidate', () async {
    await source.token();
    source.invalidate();
    expect(await source.token(), 'jwt-2');
  });

  test('shares one mint between concurrent callers', () async {
    final tokens = await Future.wait([source.token(), source.token()]);
    expect(tokens, ['jwt-1', 'jwt-1']);
    expect(minted, 1);
  });
}
