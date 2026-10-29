import 'package:cashe/core/errors/failure.dart';
import 'package:cashe/features/auth/data/auth_repository.dart';
import 'package:cashe/features/auth/domain/app_user.dart';
import 'package:cashe/features/auth/presentation/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const sam = AppUser(id: 3, displayName: 'Sam', role: UserRole.adult);

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    when(() => repository.restore()).thenAnswer((_) async => null);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: SignInScreen()),
      ),
    );
    await tester.pump();
  }

  /// The concept art pulses forever, so step past transitions instead of
  /// waiting for them to settle.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> continueWith(WidgetTester tester, String email) async {
    await tester.enterText(find.byKey(const Key('email')), email);
    await tester.tap(find.text('Continue'));
    await settle(tester);
  }

  testWidgets('rejects an invalid email before asking for a password', (
    tester,
  ) async {
    await pumpScreen(tester);
    await continueWith(tester, 'pat@example');

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.byKey(const Key('password')), findsNothing);
  });

  testWidgets('signs in with the email from the first step', (tester) async {
    when(
      () => repository.signIn(email: 'sam@example.com', password: 'secret123'),
    ).thenAnswer((_) async => sam);
    await pumpScreen(tester);
    await continueWith(tester, ' sam@example.com ');

    expect(find.text('Enter your password'), findsOneWidget);
    expect(find.text('sam@example.com'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('password')), 'secret123');
    await tester.tap(find.text('Sign in'));
    await settle(tester);

    verify(
      () => repository.signIn(email: 'sam@example.com', password: 'secret123'),
    ).called(1);
  });

  testWidgets('shows the failure message from a rejected sign-in', (
    tester,
  ) async {
    when(() => repository.signIn(email: 'pat@example.com', password: 'wrong'))
        .thenThrow(const Failure(Failure.invalidCredentials));
    await pumpScreen(tester);
    await continueWith(tester, 'pat@example.com');
    await tester.enterText(find.byKey(const Key('password')), 'wrong');
    await tester.tap(find.text('Sign in'));
    await settle(tester);

    expect(find.text('That email and password don’t match.'), findsOneWidget);
  });

  testWidgets('creating a wallet checks the password rules first', (
    tester,
  ) async {
    await pumpScreen(tester);
    await continueWith(tester, 'new@example.com');
    await tester.tap(find.text('New to Cashe? Create your wallet'));
    await settle(tester);

    expect(find.text('Create your wallet'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('name')), 'Sam');
    await tester.enterText(find.byKey(const Key('password')), 'longenough');
    await tester.tap(find.text('Create account'));
    await settle(tester);

    expect(
      find.text('Your password needs 8+ characters and a number.'),
      findsOneWidget,
    );
    verifyNever(
      () => repository.signUp(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('creates a wallet with the name and email', (tester) async {
    when(
      () => repository.signUp(
        name: 'Sam',
        email: 'new@example.com',
        password: 'secret123',
      ),
    ).thenAnswer((_) async => sam);
    await pumpScreen(tester);
    await continueWith(tester, 'new@example.com');
    await tester.tap(find.text('New to Cashe? Create your wallet'));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('name')), ' Sam ');
    await tester.enterText(find.byKey(const Key('password')), 'secret123');
    await tester.tap(find.text('Create account'));
    await settle(tester);

    verify(
      () => repository.signUp(
        name: 'Sam',
        email: 'new@example.com',
        password: 'secret123',
      ),
    ).called(1);
  });

  testWidgets('an email that already has a wallet goes to sign-in', (
    tester,
  ) async {
    when(
      () => repository.signUp(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const Failure(Failure.accountExists));
    await pumpScreen(tester);
    await continueWith(tester, 'sam@example.com');
    await tester.tap(find.text('New to Cashe? Create your wallet'));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('name')), 'Sam');
    await tester.enterText(find.byKey(const Key('password')), 'secret123');
    await tester.tap(find.text('Create account'));
    await settle(tester);

    expect(find.text('Enter your password'), findsOneWidget);
    expect(find.text('You already have a wallet. Sign in.'), findsOneWidget);
  });

  testWidgets('Change goes back to the email step', (tester) async {
    await pumpScreen(tester);
    await continueWith(tester, 'sam@example.com');
    await tester.tap(find.text('Change'));
    await settle(tester);

    expect(find.text('Spend it where you meant to.'), findsOneWidget);
  });
}
