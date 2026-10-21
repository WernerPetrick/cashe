import 'dart:async';

import 'package:cashe/core/location/location_service.dart';
import 'package:cashe/features/unlock/data/unlock_repository.dart';
import 'package:cashe/features/unlock/presentation/unlock_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/unlock_fakes.dart';

void main() {
  late FakeLocationService location;
  late FakeUnlockRepository repository;
  late StreamController<void> ticks;
  late ProviderContainer container;

  setUp(() {
    location = FakeLocationService();
    repository = FakeUnlockRepository();
    ticks = StreamController<void>.broadcast();
    container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(location),
        unlockRepositoryProvider.overrideWithValue(repository),
        pingTickerProvider.overrideWithValue(() => ticks.stream),
      ],
    );
    addTearDown(container.dispose);
  });

  UnlockController controller() =>
      container.read(unlockControllerProvider(1).notifier);
  UnlockState state() => container.read(unlockControllerProvider(1));
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test(
    'sends the first fix at once, then the latest fix on each tick',
    () async {
      container.listen(unlockControllerProvider(1), (_, _) {});
      await controller().start();

      ticks.add(null);
      await settle();
      expect(repository.pings, isEmpty, reason: 'no fix yet');

      location.fixes.add(atTuckshop);
      await settle();
      expect(repository.pings, hasLength(1));

      location.fixes.add(
        const LocationFix(
          latitude: -33.92492,
          longitude: 18.4241,
          accuracyM: 4,
          isMocked: false,
        ),
      );
      ticks.add(null);
      await settle();
      expect(repository.pings.last.latitude, -33.92492);
      expect(state().outcome, repository.nextOutcome);
    },
  );

  test(
    'passes the mock-location flag through for the server to judge',
    () async {
      container.listen(unlockControllerProvider(1), (_, _) {});
      await controller().start();
      location.fixes.add(
        const LocationFix(
          latitude: 1,
          longitude: 2,
          accuracyM: 3,
          isMocked: true,
        ),
      );
      await settle();

      expect(repository.pings.single.isMocked, isTrue);
    },
  );

  test('stops reading location when the screen goes away', () async {
    final subscription = container.listen(
      unlockControllerProvider(1),
      (_, _) {},
    );
    await controller().start();
    expect(location.fixes.hasListener, isTrue);

    subscription.close();
    await settle();

    expect(location.fixes.hasListener, isFalse);
  });

  test('reports a refused permission without reading location', () async {
    location.access = LocationAccess.deniedForever;
    container.listen(unlockControllerProvider(1), (_, _) {});
    await controller().start();

    expect(state().phase, UnlockPhase.permissionBlocked);
    expect(location.fixes.hasListener, isFalse);
  });

  test('reuses the idempotency key it is given for a spend', () async {
    container.listen(unlockControllerProvider(1), (_, _) {});
    await controller().spend(300, idempotencyKey: 'attempt-1');

    expect(repository.spends.single, (amountCents: 300, key: 'attempt-1'));
    expect(state().lastSpend?.amountCents, -300);
  });
}
