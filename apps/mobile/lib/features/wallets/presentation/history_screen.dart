import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_view.dart';
import 'history_controller.dart';
import 'widgets/ledger_entry_tile.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key, required this.walletId});

  final int walletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider(walletId));
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: history.when(
        data: (state) => NotificationListener<ScrollEndNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter < 200) {
              ref.read(historyProvider(walletId).notifier).loadMore();
            }
            return false;
          },
          child: ListView(
            children: [
              for (final entry in state.entries) LedgerEntryTile(entry: entry),
              if (state.loadingMore)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(historyProvider(walletId)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
