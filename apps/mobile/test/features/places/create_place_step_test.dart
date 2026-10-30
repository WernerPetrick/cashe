import 'package:cashe/core/errors/failure.dart';
import 'package:cashe/core/money/money.dart';
import 'package:cashe/features/places/data/places_repository.dart';
import 'package:cashe/features/places/domain/place.dart';
import 'package:cashe/features/wallets/presentation/widgets/create_place_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPlacesRepository extends Mock implements PlacesRepository {}

const tuckshop = Place(
  id: 7,
  name: 'School Tuckshop',
  latitude: -33.9249,
  longitude: 18.4241,
  radiusM: 50,
  dwellSeconds: 30,
);

const bikes = PlaceSuggestion(
  name: "Mike's Bikes",
  address: '12 Long Street, Cape Town',
  latitude: -33.923,
  longitude: 18.419,
);

void main() {
  setUpAll(
    () => registerFallbackValue(
      const PlaceDraft(
        name: '',
        latitude: 0,
        longitude: 0,
        radiusM: 50,
        dwellSeconds: 30,
      ),
    ),
  );

  late MockPlacesRepository places;
  late List<Place> picked;

  setUp(() {
    places = MockPlacesRepository();
    picked = [];
    when(() => places.near(any(), any())).thenAnswer((_) async => [tuckshop]);
  });

  Future<void> pumpStep(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [placesRepositoryProvider.overrideWithValue(places)],
        child: MaterialApp(
          home: Scaffold(
            body: CreatePlaceStep(
              amount: const Money(1000, 'ZAR'),
              selected: null,
              onPick: picked.add,
              onNext: null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump(const Duration(milliseconds: 400)); // the debounce
    await tester.pumpAndSettle();
  }

  testWidgets('short queries only filter saved places', (tester) async {
    await pumpStep(tester);

    await type(tester, 'sc');

    expect(find.text('School Tuckshop'), findsOneWidget);
    verifyNever(() => places.search(any(), any(), any()));
  });

  testWidgets('finds a real place and saves it as a Cashe place', (
    tester,
  ) async {
    when(() => places.search('bikes', any(), any()))
        .thenAnswer((_) async => [bikes]);
    when(() => places.create(any())).thenAnswer(
      (invocation) async => Place(
        id: 9,
        name: (invocation.positionalArguments.first as PlaceDraft).name,
        latitude: bikes.latitude,
        longitude: bikes.longitude,
        radiusM: 50,
        dwellSeconds: 30,
      ),
    );
    await pumpStep(tester);

    await type(tester, 'bikes');
    expect(find.text('12 Long Street, Cape Town'), findsOneWidget);
    await tester.tap(find.text("Mike's Bikes"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save place'));
    await tester.pumpAndSettle();

    final draft =
        verify(() => places.create(captureAny())).captured.single as PlaceDraft;
    expect(draft.name, "Mike's Bikes");
    expect((draft.latitude, draft.longitude), (-33.923, 18.419));
    expect(picked.single.name, "Mike's Bikes");
  });

  testWidgets('says so when the search is down', (tester) async {
    when(() => places.search(any(), any(), any()))
        .thenThrow(const Failure('place_search_unavailable'));
    await pumpStep(tester);

    await type(tester, 'coffee');

    expect(find.textContaining("Place search isn't available"), findsOneWidget);
  });
}
