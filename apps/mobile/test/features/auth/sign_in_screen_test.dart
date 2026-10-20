import 'package:cashe/core/errors/failure.dart';
import 'package:cashe/features/auth/data/auth_repository.dart';
import 'package:cashe/features/auth/presentation/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: SignInScreen()),
      ),
    );
  }

  setUp(() {
    repository = MockAuthRepository();
    when(() => repository.restore()).thenAnswer((_) async => null);
  });

  testWidgets('validates empty fields without calling Appwrite', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    verifyNever(
      () => repository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('shows the failure message from a rejected sign-in', (
    tester,
  ) async {
    when(() => repository.signIn(email: 'pat@example.com', password: 'wrong'))
        .thenThrow(const Failure(Failure.invalidCredentials));
    await pumpScreen(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'pat@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'wrong',
    );
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('That email and password don’t match.'), findsOneWidget);
  });
}
