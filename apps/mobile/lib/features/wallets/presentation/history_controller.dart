import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/wallets_repository.dart';
import '../domain/ledger_entry.dart';

class HistoryState {
  const HistoryState({
    required this.entries,
    this.nextBefore,
    this.loadingMore = false,
  });

  final List<LedgerEntry> entries;
  final int? nextBefore;
  final bool loadingMore;

  bool get hasMore => nextBefore != null;
}

final historyProvider = AsyncNotifierProvider.autoDispose
    .family<HistoryController, HistoryState, int>(HistoryController.new);

/// A wallet's full history, loaded a page at a time.
class HistoryController extends AsyncNotifier<HistoryState> {
  HistoryController(this.walletId);

  final int walletId;

  @override
  Future<HistoryState> build() async {
    final page = await ref.read(walletsRepositoryProvider).history(walletId);
    return HistoryState(entries: page.entries, nextBefore: page.nextBefore);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(
      HistoryState(
        entries: current.entries,
        nextBefore: current.nextBefore,
        loadingMore: true,
      ),
    );
    final page = await ref
        .read(walletsRepositoryProvider)
        .history(walletId, before: current.nextBefore);
    if (!ref.mounted) return;
    state = AsyncData(
      HistoryState(
        entries: [...current.entries, ...page.entries],
        nextBefore: page.nextBefore,
      ),
    );
  }
}
