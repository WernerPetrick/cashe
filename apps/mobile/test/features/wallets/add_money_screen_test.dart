import 'package:cashe/features/wallets/domain/wallet.dart';
import 'package:cashe/features/wallets/presentation/add_money_screen.dart';
import 'package:cashe/features/wallets/presentation/wallet_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('picks the bank the money comes from', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletsProvider.overrideWith((ref) async => const <Wallet>[]),
        ],
        child: const MaterialApp(home: AddMoneyScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Simulated bank'), findsOneWidget);

    await tester.tap(find.text('Simulated bank'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sandbox Savings').last);
    await tester.pumpAndSettle();

    expect(find.text('Sandbox Savings'), findsOneWidget);
    expect(find.text('Simulated bank'), findsNothing);
  });
}
