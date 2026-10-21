import 'package:cashe/app/app.dart';
import 'package:cashe/features/auth/data/auth_repository.dart';
import 'package:cashe/features/claims/presentation/claim_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('boots to sign-in when there is no session', (tester) async {
    final repository = MockAuthRepository();
    when(() => repository.restore()).thenAnswer((_) async => null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          claimTokensProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: const CasheApp(),
      ),
    );
    // The sign-in art pulses forever, so step frames instead of settling.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('Money that waits for the right place.'), findsOneWidget);
  });
}
