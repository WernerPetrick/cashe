import 'package:cashe/features/auth/data/auth_repository.dart';
import 'package:cashe/features/auth/domain/app_user.dart';
import 'package:cashe/features/home/presentation/home_tab.dart';
import 'package:cashe/features/wallets/domain/wallet.dart';
import 'package:cashe/features/wallets/presentation/wallet_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const sam = AppUser(id: 3, displayName: 'Sam', role: UserRole.adult);

const coffee = Wallet(
  id: 1,
  kind: WalletKind.gift,
  name: 'Good Coffee',
  status: WalletStatus.active,
  role: WalletRole.owner,
  place: PlaceRef(id: 1, name: 'Test Tuckshop'),
  currency: 'ZAR',
  balanceCents: 1000,
  fundedCents: 8000,
  funderName: 'BigDog Daddy',
);

void main() {
  Future<void> pumpHome(WidgetTester tester, List<Wallet> wallets) async {
    final auth = MockAuthRepository();
    when(auth.restore).thenAnswer((_) async => sam);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          walletsProvider.overrideWith((ref) async => wallets),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeTab())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('no spots: says how to start one', (tester) async {
    await pumpHome(tester, []);

    expect(find.text('0 spots'), findsOneWidget);
    expect(find.textContaining('No spots yet'), findsOneWidget);
    expect(find.text('New spot'), findsOneWidget);
    expect(find.text('Send cash'), findsOneWidget);
  });

  testWidgets('lists my spots, not gifts I sent', (tester) async {
    const sent = Wallet(
      id: 2,
      kind: WalletKind.gift,
      name: 'Pocket money',
      status: WalletStatus.active,
      role: WalletRole.funder,
      place: PlaceRef(id: 1, name: 'Test Tuckshop'),
      currency: 'ZAR',
      balanceCents: 500,
      fundedCents: 500,
      funderName: 'Sam Parent',
      ownerName: 'Sam',
    );
    await pumpHome(tester, [coffee, sent]);

    expect(find.text('1 spot'), findsOneWidget);
    expect(find.text('Good Coffee'), findsOneWidget);
    expect(find.text('Pocket money'), findsNothing);
    expect(find.text('Total balance'), findsNothing);
  });
}
