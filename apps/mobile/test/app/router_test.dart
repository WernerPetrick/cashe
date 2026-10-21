import 'package:cashe/app/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const loading = AsyncLoading<Object?>();
  const signedOut = AsyncData<Object?>(null);
  const signedIn = AsyncData<Object?>('user');

  String? redirect(AsyncValue<Object?> auth, String location) =>
      authRedirect(auth, Uri.parse(location));

  test('holds on the splash while restoring', () {
    expect(redirect(loading, '/'), Routes.splash);
    expect(redirect(loading, Routes.splash), isNull);
  });

  test('sends signed-out users to sign-in', () {
    expect(redirect(signedOut, '/'), Routes.signIn);
    expect(redirect(signedOut, Routes.signIn), isNull);
    expect(
      redirect(const AsyncError<Object?>('x', StackTrace.empty), Routes.splash),
      Routes.signIn,
    );
  });

  test('sends signed-in users home', () {
    expect(redirect(signedIn, Routes.signIn), Routes.home);
    expect(redirect(signedIn, Routes.splash), Routes.home);
    expect(redirect(signedIn, '/wallets/3'), isNull);
  });

  test('resumes a claim link after sign-in', () {
    final gate = redirect(signedOut, '/claim/abc123');
    expect(gate, '/sign-in?from=%2Fclaim%2Fabc123');
    expect(redirect(signedIn, gate!), '/claim/abc123');
  });

  test('keeps the destination through the splash', () {
    final splash = redirect(loading, '/claim/abc123')!;
    expect(redirect(signedOut, splash), '/sign-in?from=%2Fclaim%2Fabc123');
  });

  test('ignores a destination outside the app', () {
    expect(
      redirect(signedIn, '/sign-in?from=https://evil.example'),
      Routes.home,
    );
    expect(redirect(signedIn, '/sign-in?from=//evil.example'), Routes.home);
  });
}
