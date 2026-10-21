import 'dart:async';

import 'package:cashe/core/location/location_service.dart';
import 'package:cashe/features/places/domain/place.dart';
import 'package:cashe/features/unlock/data/unlock_repository.dart';
import 'package:cashe/features/unlock/domain/ping_outcome.dart';
import 'package:cashe/features/wallets/domain/ledger_entry.dart';
import 'package:cashe/features/wallets/domain/time_window.dart';
import 'package:cashe/features/wallets/domain/wallet.dart';

const tuckshop = Place(
  id: 7,
  name: 'School Tuckshop',
  latitude: -33.9249,
  longitude: 18.4241,
  radiusM: 50,
  dwellSeconds: 30,
);

const recess = TimeWindow(
  daysOfWeek: [1, 2, 3, 4, 5],
  startsAt: '10:30',
  endsAt: '11:00',
  timeZone: 'Africa/Johannesburg',
);

const tuckshopGift = WalletDetail(
  id: 1,
  kind: WalletKind.gift,
  name: 'Tuckshop money',
  status: WalletStatus.active,
  role: WalletRole.owner,
  place: tuckshop,
  currency: 'USD',
  balanceCents: 1000,
  funderName: 'Pat Parent',
  ownerName: 'Sam Friend',
  timeWindows: [recess],
  recentEntries: [],
);

const atTuckshop = LocationFix(
  latitude: -33.9249,
  longitude: 18.4241,
  accuracyM: 6,
  isMocked: false,
);

class FakeLocationService implements LocationService {
  FakeLocationService({this.access = LocationAccess.granted});

  LocationAccess access;
  final fixes = StreamController<LocationFix>.broadcast();
  int settingsOpened = 0;

  @override
  Future<LocationAccess> requestAccess() async => access;

  @override
  Stream<LocationFix> watch() => fixes.stream;

  @override
  Future<void> openSettings() async => settingsOpened++;
}

class FakeUnlockRepository implements UnlockRepository {
  final pings = <PingRequest>[];
  final spends = <({int amountCents, String key})>[];
  PingOutcome nextOutcome = const PingOutcome(
    status: PingStatus.dwelling,
    dwellProgressSeconds: 0,
    dwellRequiredSeconds: 30,
  );

  @override
  Future<PingOutcome> ping(int walletId, PingRequest request) async {
    pings.add(request);
    return nextOutcome;
  }

  @override
  Future<LedgerEntry> spend(
    int walletId, {
    required int amountCents,
    required String idempotencyKey,
  }) async {
    spends.add((amountCents: amountCents, key: idempotencyKey));
    return LedgerEntry(
      id: 99,
      kind: LedgerKind.spend,
      amountCents: -amountCents,
      currency: 'USD',
      placeName: tuckshop.name,
      createdAt: DateTime.utc(2026, 10, 21, 8, 42),
    );
  }
}

PingOutcome outcome(
  PingStatus status, {
  int progress = 0,
  DateTime? unlockedUntil,
  RejectionReason? reason,
  bool? inside,
  bool? inWindow,
}) => PingOutcome(
  status: status,
  insideZone: inside,
  inTimeWindow: inWindow,
  dwellProgressSeconds: progress,
  dwellRequiredSeconds: 30,
  unlockedUntil: unlockedUntil,
  reason: reason,
);
