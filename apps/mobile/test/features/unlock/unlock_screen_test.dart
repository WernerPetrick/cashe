import 'dart:async';

import 'package:cashe/core/location/location_service.dart';
import 'package:cashe/core/widgets/cashe_widgets.dart';
import 'package:cashe/features/unlock/data/unlock_repository.dart';
import 'package:cashe/features/unlock/domain/ping_outcome.dart';
import 'package:cashe/features/unlock/presentation/unlock_controller.dart';
import 'package:cashe/features/unlock/presentation/unlock_screen.dart';
import 'package:cashe/features/wallets/presentation/wallet_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/unlock_fakes.dart';

void main() {
  late FakeLocationService location;
  late FakeUnlockRepository repository;

  setUp(() {
    location = FakeLocationService();
    repository = FakeUnlockRepository();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    // A phone-sized screen (the design's 412 × 892), not the default 800 × 600.
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationServiceProvider.overrideWithValue(location),
          unlockRepositoryProvider.overrideWithValue(repository),
          pingTickerProvider.overrideWithValue(() => const Stream.empty()),
          walletDetailProvider.overrideWith((ref, id) async => tuckshopGift),
        ],
        child: const MaterialApp(home: UnlockScreen(walletId: 1)),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Agrees to share location and delivers one fix, answered with [result].
  Future<void> arriveWith(WidgetTester tester, PingOutcome result) async {
    repository.nextOutcome = result;
    await tester.tap(find.text('Share my location'));
    await tester.pump(); // "Finding your location" animates forever, so no pumpAndSettle
    location.fixes.add(atTuckshop);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('explains why it wants location before asking', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Check in at School Tuckshop'), findsOneWidget);
    expect(find.textContaining('never stored'), findsOneWidget);
    expect(location.fixes.hasListener, isFalse);
  });

  testWidgets('asks again when permission is refused', (tester) async {
    location.access = LocationAccess.denied;
    await pumpScreen(tester);
    await tester.tap(find.text('Share my location'));
    await tester.pumpAndSettle();

    expect(find.text('Location is needed here'), findsOneWidget);
  });

  testWidgets('sends people to Settings when permission is blocked', (
    tester,
  ) async {
    location.access = LocationAccess.deniedForever;
    await pumpScreen(tester);
    await tester.tap(find.text('Share my location'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open settings'));

    expect(location.settingsOpened, 1);
  });

  testWidgets('shows it is finding the location before the first answer', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Share my location'));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('ping-status-locating')), findsOneWidget);
  });

  testWidgets('outside the zone: still locked', (tester) async {
    await pumpScreen(tester);
    await arriveWith(
      tester,
      outcome(PingStatus.outsideZone, inside: false, inWindow: true),
    );

    expect(find.byKey(const Key('ping-status-outside_zone')), findsOneWidget);
    expect(find.text('Still locked'), findsOneWidget);
    expect(find.textContaining('within 50 m'), findsOneWidget);
  });

  testWidgets('outside the time window', (tester) async {
    await pumpScreen(tester);
    await arriveWith(
      tester,
      outcome(PingStatus.outsideTimeWindow, inside: true, inWindow: false),
    );

    expect(find.text('Outside the allowed times'), findsOneWidget);
    expect(find.textContaining('Mon–Fri 10:30–11:00'), findsOneWidget);
  });

  testWidgets('dwelling fills the ring', (tester) async {
    await pumpScreen(tester);
    await arriveWith(
      tester,
      outcome(PingStatus.dwelling, progress: 15, inside: true, inWindow: true),
    );

    expect(find.text('Checking you’re at School Tuckshop'), findsOneWidget);
    expect(find.text('Stay here · 15 s to go'), findsOneWidget);
    final ring = tester.widget<RingDial>(find.byType(RingDial));
    expect(ring.progress, 0.5);
  });

  testWidgets('a mock location is rejected on screen', (tester) async {
    await pumpScreen(tester);
    await arriveWith(
      tester,
      outcome(PingStatus.rejected, reason: RejectionReason.mockLocation),
    );

    expect(find.text('Location rejected'), findsOneWidget);
    expect(find.textContaining('mock (fake) location'), findsOneWidget);
  });

  testWidgets('a low-accuracy fix is rejected on screen', (tester) async {
    await pumpScreen(tester);
    await arriveWith(
      tester,
      outcome(PingStatus.rejected, reason: RejectionReason.lowAccuracy),
    );

    expect(find.text('Location not precise enough'), findsOneWidget);
  });

  testWidgets('unlocked: the card machine charges and the tap pays', (
    tester,
  ) async {
    await pumpScreen(tester);
    final until = DateTime.now().add(const Duration(minutes: 10));
    await arriveWith(
      tester,
      outcome(
        PingStatus.unlocked,
        progress: 30,
        unlockedUntil: until,
        inside: true,
        inWindow: true,
      ),
    );

    expect(find.byKey(const Key('ping-status-unlocked')), findsOneWidget);
    expect(find.text('Tap your phone on the card machine'), findsOneWidget);
    expect(find.textContaining('Relocks in'), findsOneWidget);

    // The pulsing rings never settle, so step frames instead of pumpAndSettle.
    await tester.tap(find.text('PROTOTYPE · SIMULATE CARD TAP'));
    await tester.pump(); // starts the sheet's slide-in
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const Key('key-3')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('simulate-tap')));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(repository.spends.single.amountCents, 300);
    expect(find.byKey(const Key('unlock-paid')), findsOneWidget);
    final paid = find.byKey(const Key('unlock-paid'));
    expect(
      find.descendant(of: paid, matching: find.text('\$3.00')),
      findsOneWidget,
    );
    expect(find.text('Paid at School Tuckshop'), findsOneWidget);
  });
}
