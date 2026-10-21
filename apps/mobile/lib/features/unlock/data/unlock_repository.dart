import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_result.dart';
import '../../wallets/domain/ledger_entry.dart';
import '../domain/ping_outcome.dart';

final unlockRepositoryProvider = Provider<UnlockRepository>((ref) {
  return UnlockRepository(ref.watch(apiClientProvider));
});

/// Presence pings and spends. The ping's coordinates are sent once and not kept.
class UnlockRepository {
  UnlockRepository(this._api);

  final ApiClient _api;

  Future<PingOutcome> ping(int walletId, PingRequest request) async =>
      (await _api.post(
        '/wallets/$walletId/presence_pings',
        PingOutcome.fromJson,
        body: request.toJson(),
      )).unwrap();

  /// [idempotencyKey] must be reused when retrying the same spend.
  Future<LedgerEntry> spend(
    int walletId, {
    required int amountCents,
    required String idempotencyKey,
  }) async {
    final body = {
      'amount_cents': amountCents,
      'idempotency_key': idempotencyKey,
    };
    return (await _api.post(
      '/wallets/$walletId/spends',
      LedgerEntry.fromJson,
      body: body,
    )).unwrap();
  }
}
