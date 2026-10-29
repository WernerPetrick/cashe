import 'dart:async';

import 'package:cashe/app/app.dart';
import 'package:cashe/core/api/api_client.dart';
import 'package:cashe/core/auth/appwrite_providers.dart';
import 'package:cashe/core/location/location_service.dart';
import 'package:cashe/features/claims/presentation/claim_links.dart';
import 'package:cashe/features/unlock/presentation/unlock_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_cashe_api.dart';
import 'unlock_fakes.dart';

const parentEmail = 'pat@example.com';
const childEmail = 'sam@example.com';
const password = 'secret123';

/// The Phase 2 happy path through the real app (router, screens, controllers,
/// repositories, API client and auth), with only the edges faked: Appwrite,
/// the Rails API, GPS, the ping timer and incoming claim links.
///
/// Pat sends Sam a $10 gift for the school tuckshop on weekdays with an expiry;
/// Sam claims it from the link, checks in at the tuckshop until it unlocks and
/// pays $3; Pat then sees it was claimed by Sam and spent.
Future<void> runHappyPath(WidgetTester tester) async {
  // A tap that lands on something else (e.g. a snack bar) fails the test.
  WidgetController.hitTestWarningShouldBeFatal = true;
  addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
  final api = FakeCasheApi(
    places: [
      {
        'id': 7,
        'name': 'School Tuckshop',
        'latitude': -33.9249,
        'longitude': 18.4241,
        'radius_m': 50,
        'dwell_seconds': 30,
        'distance_m': 120,
      },
    ],
    names: {parentEmail: 'Pat Parent', childEmail: 'Sam'},
  );
  final location = FakeLocationService();
  final ticks = StreamController<void>.broadcast();
  final links = StreamController<String>.broadcast();
  addTearDown(ticks.close);
  addTearDown(links.close);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appwriteAccountProvider.overrideWithValue(
          FakeAccount({parentEmail: password, childEmail: password}),
        ),
        apiClientProvider.overrideWith(
          (ref) => ApiClient(
            baseUrl: Uri.parse('http://cashe.test'),
            jwt: ref.watch(jwtSourceProvider),
            transport: api,
          ),
        ),
        locationServiceProvider.overrideWithValue(location),
        pingTickerProvider.overrideWithValue(() => ticks.stream),
        claimTokensProvider.overrideWith((ref) => links.stream),
      ],
      child: const CasheApp(),
    ),
  );
  await settle(tester);

  // Pat sends a gift.
  await signIn(tester, parentEmail);
  expect(find.text('Hi Pat'), findsOneWidget);
  await tapText(tester, 'Send cash');
  for (final key in ['1', '0']) {
    await tester.tap(find.byKey(Key('key-$key')));
  }
  await tapText(tester, 'USD');
  await tapText(tester, 'Next: choose place');
  await tapText(tester, 'School Tuckshop');
  await tapText(tester, 'Next: review');
  await tapText(tester, 'Add'); // a time window: the dialog's Mon–Fri default
  await tester.tap(find.widgetWithText(FilledButton, 'Add'));
  await settle(tester);
  await tapText(tester, 'Set'); // an expiry date
  await tapText(tester, 'OK');
  await tapText(tester, r'Send $10.00 gift');

  final created = api.bodies['POST /wallets']!;
  expect(created['kind'], 'gift');
  expect(created['currency'], 'USD');
  expect(created['time_windows'], [
    {
      'days_of_week': [1, 2, 3, 4, 5],
      'starts_at': '10:30',
      'ends_at': '11:00',
      'time_zone': 'Africa/Johannesburg',
    },
  ]);
  expect(created['expires_at'], isNotNull);
  expect(api.bodies['POST /wallets/1/deposits']!['amount_cents'], 1000);
  expect(find.text('cashe://claim/claim-token-1'), findsOneWidget);
  await tapText(tester, 'Done');
  await signOut(tester);

  // Sam opens the link: sign in first, then the gift is claimed.
  links.add('claim-token-1');
  await settle(tester);
  await signIn(tester, childEmail);
  expect(api.requests, contains('POST /gift_claims'));
  expect(find.text('School Tuckshop is yours'), findsOneWidget);
  await tester.pump(const Duration(seconds: 5)); // the snack bar covers Unlock
  await settle(tester);

  // Sam checks in at the tuckshop until it unlocks.
  await tapText(tester, 'Unlock');
  await tapText(tester, 'Share my location');
  location.fixes.add(atTuckshop);
  await settle(tester);
  expect(find.text('Stay here · 30 s to go'), findsOneWidget);
  ticks.add(null);
  await settle(tester);
  expect(find.text('Stay here · 15 s to go'), findsOneWidget);
  ticks.add(null);
  await settle(tester);
  expect(find.byKey(const Key('ping-status-unlocked')), findsOneWidget);

  // ...and pays $3 with the simulated card tap.
  await tapText(tester, 'PROTOTYPE · SIMULATE CARD TAP');
  await tester.tap(find.byKey(const Key('key-3')));
  await tester.pump(); // the charge button enables once there's an amount
  await tester.tap(find.byKey(const Key('simulate-tap')));
  await settle(tester);
  expect(api.bodies['POST /wallets/1/spends']!['amount_cents'], 300);
  expect(find.byKey(const Key('unlock-paid')), findsOneWidget);
  expect(find.text('Paid at School Tuckshop'), findsOneWidget);
  await tapText(tester, 'Done');
  expect(find.text(r'$7.00'), findsWidgets);
  await signOut(tester);

  // Pat sees who claimed it and what was spent, but not where Sam was.
  await signIn(tester, parentEmail);
  await tapText(tester, 'Activity');
  expect(find.textContaining('Claimed by Sam'), findsWidgets);
  await tapText(tester, 'School Tuckshop');
  expect(find.textContaining('Claimed by Sam'), findsWidgets);
  expect(find.text(r'$7.00'), findsWidgets);
  expect(find.textContaining('-33.92'), findsNothing);

  expect(api.unhandled, isEmpty);
}

/// Pumps frames for a while. The app has never-ending animations (pulsing
/// rings), so pumpAndSettle would never return.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tapText(
  WidgetTester tester,
  String text, {
  bool first = false,
}) async {
  final finder = first ? find.text(text).first : find.text(text);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester);
}

Future<void> signIn(WidgetTester tester, String email) async {
  await tester.enterText(find.byKey(const Key('email')), email);
  await tapText(tester, 'Continue');
  await tester.enterText(find.byKey(const Key('password')), password);
  await tapText(tester, 'Sign in');
}

/// From any screen under home: back to Home, then Me → Sign out.
Future<void> signOut(WidgetTester tester) async {
  if (find.text('Home').evaluate().length == 1 &&
      find.text('Me').evaluate().isEmpty) {
    await tapText(tester, 'Home');
  }
  await tapText(tester, 'Me');
  await tapText(tester, 'Sign out');
}
