import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/money/money.dart';

part 'ledger_entry.freezed.dart';
part 'ledger_entry.g.dart';

enum LedgerKind { deposit, spend, refund }

@freezed
abstract class LedgerEntry with _$LedgerEntry {
  const LedgerEntry._();

  const factory LedgerEntry({
    required int id,
    required LedgerKind kind,
    required int amountCents,
    required String currency,
    String? placeName,
    required DateTime createdAt,
  }) = _LedgerEntry;

  factory LedgerEntry.fromJson(Map<String, dynamic> json) =>
      _$LedgerEntryFromJson(json);

  Money get amount => Money(amountCents, currency);
}

@freezed
abstract class LedgerPage with _$LedgerPage {
  const factory LedgerPage({
    required List<LedgerEntry> entries,
    int? nextBefore,
  }) = _LedgerPage;

  factory LedgerPage.fromJson(Map<String, dynamic> json) =>
      _$LedgerPageFromJson(json);
}
