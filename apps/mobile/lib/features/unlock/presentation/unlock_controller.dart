import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/ids/idempotency_key.dart';
import '../../../core/location/location_service.dart';
import '../../wallets/domain/ledger_entry.dart';
import '../data/unlock_repository.dart';
import '../domain/ping_outcome.dart';

/// How often the unlock screen reports location (CLAUDE.md: every 10–15 s).
const pingInterval = Duration(seconds: 12);

/// Ticks that trigger a ping. Swapped for a manual stream in tests.
final pingTickerProvider = Provider<Stream<void> Function()>(
  (ref) =>
      () => Stream<void>.periodic(pingInterval),
);

enum UnlockPhase {
  starting,
  needsPermission,
  permissionBlocked,
  serviceOff,
  tracking,
}

class UnlockState {
  const UnlockState({
    this.phase = UnlockPhase.starting,
    this.outcome,
    this.failure,
    this.spending = false,
    this.lastSpend,
  });

  final UnlockPhase phase;
  final PingOutcome? outcome;
  final Failure? failure;
  final bool spending;
  final LedgerEntry? lastSpend;

  UnlockState copyWith({
    UnlockPhase? phase,
    PingOutcome? outcome,
    Failure? failure,
    bool clearFailure = false,
    bool? spending,
    LedgerEntry? lastSpend,
    bool clearLastSpend = false,
  }) {
    return UnlockState(
      phase: phase ?? this.phase,
      outcome: outcome ?? this.outcome,
      failure: clearFailure ? null : failure ?? this.failure,
      spending: spending ?? this.spending,
      lastSpend: clearLastSpend ? null : lastSpend ?? this.lastSpend,
    );
  }
}

final unlockControllerProvider = NotifierProvider.autoDispose
    .family<UnlockController, UnlockState, int>(UnlockController.new);

/// Runs the ping loop for one wallet while the unlock screen is open: the latest
/// location fix is sent on the first reading and then on every tick. Leaving the
/// screen disposes this, which stops location updates.
class UnlockController extends Notifier<UnlockState> {
  UnlockController(this.walletId);

  final int walletId;

  StreamSubscription<LocationFix>? _fixes;
  StreamSubscription<void>? _ticks;
  LocationFix? _latest;
  bool _sending = false;

  @override
  UnlockState build() {
    ref.onDispose(_stop);
    return const UnlockState();
  }

  /// Asks for location access and, once granted, starts the ping loop.
  Future<void> start() async {
    final access = await ref.read(locationServiceProvider).requestAccess();
    if (!ref.mounted) return;
    if (access != LocationAccess.granted) {
      state = state.copyWith(phase: _phaseFor(access));
      return;
    }
    state = state.copyWith(phase: UnlockPhase.tracking);
    _fixes = ref.read(locationServiceProvider).watch().listen(_onFix);
    _ticks = ref.read(pingTickerProvider)().listen((_) => _send());
  }

  /// Back from the "paid" screen to the unlocked one, to pay again.
  void dismissSpend() => state = state.copyWith(clearLastSpend: true);

  Future<void> openSettings() =>
      ref.read(locationServiceProvider).openSettings();

  /// Spends during the unlock. One key per attempt so a retry can't charge twice.
  Future<LedgerEntry?> spend(int amountCents, {String? idempotencyKey}) async {
    state = state.copyWith(spending: true, clearFailure: true);
    try {
      final entry = await ref
          .read(unlockRepositoryProvider)
          .spend(
            walletId,
            amountCents: amountCents,
            idempotencyKey: idempotencyKey ?? newIdempotencyKey(),
          );
      if (ref.mounted) {
        state = state.copyWith(spending: false, lastSpend: entry);
      }
      return entry;
    } on Failure catch (failure) {
      if (ref.mounted) {
        state = state.copyWith(spending: false, failure: failure);
      }
      return null;
    }
  }

  void _onFix(LocationFix fix) {
    final first = _latest == null;
    _latest = fix;
    if (first) _send();
  }

  Future<void> _send() async {
    final fix = _latest;
    if (fix == null || _sending) return;
    _sending = true;
    try {
      final outcome = await ref
          .read(unlockRepositoryProvider)
          .ping(walletId, _request(fix));
      if (ref.mounted) {
        state = state.copyWith(outcome: outcome, clearFailure: true);
      }
    } on Failure catch (failure) {
      if (ref.mounted) state = state.copyWith(failure: failure);
    } finally {
      _sending = false;
    }
  }

  PingRequest _request(LocationFix fix) => PingRequest(
    latitude: fix.latitude,
    longitude: fix.longitude,
    accuracyM: fix.accuracyM,
    isMocked: fix.isMocked,
  );

  UnlockPhase _phaseFor(LocationAccess access) => switch (access) {
    LocationAccess.deniedForever => UnlockPhase.permissionBlocked,
    LocationAccess.serviceOff => UnlockPhase.serviceOff,
    _ => UnlockPhase.needsPermission,
  };

  void _stop() {
    _fixes?.cancel();
    _ticks?.cancel();
    _latest = null;
  }
}
