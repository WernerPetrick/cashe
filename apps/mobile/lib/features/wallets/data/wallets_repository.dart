import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../domain/ledger_entry.dart';
import '../domain/wallet.dart';

final walletsRepositoryProvider = Provider<WalletsRepository>((ref) {
  return WalletsRepository(ref.watch(apiClientProvider));
});

/// Wallets, top-ups, gift claims and history. Throws Failure for expected errors.
class WalletsRepository {
  WalletsRepository(this._api);

  final ApiClient _api;

  Future<List<Wallet>> list() async {
    final result = await _api.get('/wallets', (json) {
      return (json['wallets'] as List)
          .map((wallet) => Wallet.fromJson(wallet as Map<String, dynamic>))
          .toList();
    });
    return result.unwrap();
  }

  Future<WalletDetail> get(int id) async =>
      (await _api.get('/wallets/$id', WalletDetail.fromJson)).unwrap();

  /// For a gift, the result's claimUrl is the only time the link is available.
  Future<WalletDetail> create(WalletDraft draft) async => (await _api.post(
    '/wallets',
    WalletDetail.fromJson,
    body: draft.toJson(),
  )).unwrap();

  /// [idempotencyKey] must be reused when retrying the same top-up.
  Future<LedgerEntry> deposit(
    int walletId, {
    required int amountCents,
    required String idempotencyKey,
  }) async {
    final body = {
      'amount_cents': amountCents,
      'idempotency_key': idempotencyKey,
    };
    return (await _api.post(
      '/wallets/$walletId/deposits',
      LedgerEntry.fromJson,
      body: body,
    )).unwrap();
  }

  Future<WalletDetail> cancel(int walletId) async => (await _api.post(
    '/wallets/$walletId/cancellation',
    WalletDetail.fromJson,
  )).unwrap();

  Future<WalletDetail> claim(String token) async => (await _api.post(
    '/gift_claims',
    WalletDetail.fromJson,
    body: {'token': token},
  )).unwrap();

  Future<LedgerPage> history(int walletId, {int? before}) async {
    final query = before == null ? '' : '?before=$before';
    return (await _api.get(
      '/wallets/$walletId/ledger_entries$query',
      LedgerPage.fromJson,
    )).unwrap();
  }
}
