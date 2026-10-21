import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/cashe_widgets.dart';
import '../../../core/widgets/error_view.dart';
import '../../wallets/data/wallets_repository.dart';
import '../../wallets/domain/ledger_entry.dart';
import '../../wallets/presentation/wallet_providers.dart';
import '../../wallets/presentation/widgets/ledger_entry_tile.dart';

typedef ActivityItem = ({LedgerEntry entry, String walletName});

/// Recent entries across all my wallets: the first page of each, newest first.
final activityProvider = FutureProvider.autoDispose<List<ActivityItem>>((
  ref,
) async {
  final wallets = await ref.watch(walletsProvider.future);
  final repository = ref.watch(walletsRepositoryProvider);
  final pages = await Future.wait(
    wallets.map((wallet) => repository.history(wallet.id)),
  );
  final items = [
    for (final (index, page) in pages.indexed)
      for (final entry in page.entries)
        (entry: entry, walletName: wallets[index].name),
  ];
  items.sort((a, b) => b.entry.createdAt.compareTo(a.entry.createdAt));
  return items.take(50).toList();
});

class ActivityTab extends ConsumerWidget {
  const ActivityTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(activityProvider);
    return activity.when(
      data: (items) => RefreshIndicator(
        onRefresh: () => ref.refresh(activityProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          children: [
            const MonoLabel('Activity'),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Nothing yet.'),
              ),
            for (final item in items)
              LedgerEntryTile(entry: item.entry, walletName: item.walletName),
          ],
        ),
      ),
      error: (error, _) => ErrorView(
        error: error,
        onRetry: () => ref.invalidate(activityProvider),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
