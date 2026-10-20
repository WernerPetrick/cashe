import 'package:cashe/app/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const loading = AsyncLoading<Object?>();
  const signedOut = AsyncData<Object?>(null);
  const signedIn = AsyncData<Object?>('user');

  test('holds on the splash while restoring', () {
    expect(authRedirect(loading, Routes.home), Routes.splash);
    expect(authRedirect(loading, Routes.splash), isNull);
  });

  test('sends signed-out users to sign-in', () {
    expect(authRedirect(signedOut, Routes.home), Routes.signIn);
    expect(authRedirect(signedOut, Routes.signIn), isNull);
    expect(
      authRedirect(
        const AsyncError<Object?>('x', StackTrace.empty),
        Routes.splash,
      ),
      Routes.signIn,
    );
  });

  test('sends signed-in users home', () {
    expect(authRedirect(signedIn, Routes.signIn), Routes.home);
    expect(authRedirect(signedIn, Routes.splash), Routes.home);
    expect(authRedirect(signedIn, Routes.home), isNull);
  });
}
