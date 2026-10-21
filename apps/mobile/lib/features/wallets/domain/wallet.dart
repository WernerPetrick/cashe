import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/money/money.dart';
import '../../places/domain/place.dart';
import 'ledger_entry.dart';
import 'time_window.dart';

part 'wallet.freezed.dart';
part 'wallet.g.dart';

enum WalletKind { goal, gift }

enum WalletStatus { pending, active, cancelled, expired }

/// My relationship to a wallet. A goal's owner is also its funder.
enum WalletRole { owner, funder }

@freezed
abstract class PlaceRef with _$PlaceRef {
  const factory PlaceRef({required int id, required String name}) = _PlaceRef;

  factory PlaceRef.fromJson(Map<String, dynamic> json) =>
      _$PlaceRefFromJson(json);
}

/// A wallet in a list (`GET /wallets`).
@freezed
abstract class Wallet with _$Wallet {
  const Wallet._();

  const factory Wallet({
    required int id,
    required WalletKind kind,
    required String name,
    required WalletStatus status,
    required WalletRole role,
    required PlaceRef place,
    required String currency,
    required int balanceCents,
    @Default(0) int fundedCents,
    int? targetCents,
    DateTime? expiresAt,
    DateTime? claimExpiresAt,
    DateTime? claimedAt,
    required String funderName,
    String? ownerName,
  }) = _Wallet;

  factory Wallet.fromJson(Map<String, dynamic> json) => _$WalletFromJson(json);

  Money get balance => Money(balanceCents, currency);
  Money? get target =>
      targetCents == null ? null : Money(targetCents!, currency);
}

/// One wallet with its rules and recent history (`GET /wallets/:id`).
/// [claimUrl] is only set in the response to creating a gift, and never again.
@freezed
abstract class WalletDetail with _$WalletDetail {
  const WalletDetail._();

  const factory WalletDetail({
    required int id,
    required WalletKind kind,
    required String name,
    required WalletStatus status,
    required WalletRole role,
    required Place place,
    required String currency,
    required int balanceCents,
    @Default(0) int fundedCents,
    int? targetCents,
    DateTime? expiresAt,
    DateTime? claimExpiresAt,
    DateTime? claimedAt,
    required String funderName,
    String? ownerName,
    required List<TimeWindow> timeWindows,
    required List<LedgerEntry> recentEntries,
    DateTime? unlockedUntil,
    String? claimUrl,
  }) = _WalletDetail;

  factory WalletDetail.fromJson(Map<String, dynamic> json) =>
      _$WalletDetailFromJson(json);

  Money get balance => Money(balanceCents, currency);
  Money? get target =>
      targetCents == null ? null : Money(targetCents!, currency);
  bool get isOwner => role == WalletRole.owner;
  bool get isFunder => role == WalletRole.funder || kind == WalletKind.goal;
}

/// What the app sends to create a goal or gift.
@freezed
abstract class WalletDraft with _$WalletDraft {
  const factory WalletDraft({
    required WalletKind kind,
    required String name,
    required int placeId,
    required String currency,
    int? targetCents,
    DateTime? expiresAt,
    @Default([]) List<TimeWindow> timeWindows,
  }) = _WalletDraft;

  factory WalletDraft.fromJson(Map<String, dynamic> json) =>
      _$WalletDraftFromJson(json);
}
