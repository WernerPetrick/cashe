import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/wallets_repository.dart';
import '../domain/ledger_entry.dart';
import '../domain/wallet.dart';

final walletsProvider = FutureProvider.autoDispose<List<Wallet>>(
  (ref) => ref.watch(walletsRepositoryProvider).list(),
);

final walletDetailProvider = FutureProvider.autoDispose
    .family<WalletDetail, int>(
      (ref, id) => ref.watch(walletsRepositoryProvider).get(id),
    );

final walletActionsProvider = Provider<WalletActions>(WalletActions.new);

/// The wallet use cases screens call. Each refreshes the data it changed.
class WalletActions {
  WalletActions(this._ref);

  final Ref _ref;

  WalletsRepository get _repository => _ref.read(walletsRepositoryProvider);

  Future<WalletDetail> create(WalletDraft draft) async {
    final wallet = await _repository.create(draft);
    _ref.invalidate(walletsProvider);
    return wallet;
  }

  Future<LedgerEntry> topUp(
    int walletId,
    int amountCents,
    String idempotencyKey,
  ) async {
    final entry = await _repository.deposit(
      walletId,
      amountCents: amountCents,
      idempotencyKey: idempotencyKey,
    );
    _refresh(walletId);
    return entry;
  }

  Future<void> cancel(int walletId) async {
    await _repository.cancel(walletId);
    _refresh(walletId);
  }

  Future<WalletDetail> claim(String token) async {
    final wallet = await _repository.claim(token);
    _ref.invalidate(walletsProvider);
    return wallet;
  }

  void refresh(int walletId) => _refresh(walletId);

  void _refresh(int walletId) {
    _ref.invalidate(walletDetailProvider(walletId));
    _ref.invalidate(walletsProvider);
  }
}
