import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/cashe_widgets.dart';
import '../../../core/widgets/error_view.dart';
import '../domain/pot_progress.dart';
import '../domain/wallet.dart';
import '../domain/wallet_text.dart';
import 'wallet_providers.dart';
import 'widgets/ledger_entry_tile.dart';

/// A pot, as in the design: name, ring, rules and history, with Unlock for the owner.
class WalletDetailScreen extends ConsumerWidget {
  const WalletDetailScreen({super.key, required this.walletId});

  final int walletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletDetailProvider(walletId));
    return Scaffold(
      body: SafeArea(
        child: wallet.when(
          data: (detail) => _Pot(wallet: detail),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(walletDetailProvider(walletId)),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _Pot extends ConsumerWidget {
  const _Pot({required this.wallet});

  final WalletDetail wallet;

  String get _meta {
    if (wallet.kind == WalletKind.goal) {
      return '${wallet.place.name} · locked by you';
    }
    final people = WalletText.people(
      kind: wallet.kind,
      role: wallet.role,
      status: wallet.status,
      funderName: wallet.funderName,
      ownerName: wallet.ownerName,
    );
    return '${wallet.place.name} · ${people!.replaceFirst('From ', 'gift from ')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.refresh(walletDetailProvider(wallet.id).future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
              children: [
                PillButton(label: 'Home', onPressed: () => context.go('/')),
                const SizedBox(height: 20),
                Text(
                  wallet.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _meta,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: CasheColors.muted,
                  ),
                ),
                const SizedBox(height: 26),
                Center(child: _BigRing(wallet: wallet)),
                const SizedBox(height: 26),
                _Rules(wallet: wallet),
                const SizedBox(height: 22),
                _History(wallet: wallet),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: _Actions(wallet: wallet),
        ),
      ],
    );
  }
}

class _BigRing extends StatelessWidget {
  const _BigRing({required this.wallet});

  final WalletDetail wallet;

  @override
  Widget build(BuildContext context) {
    final progress = PotProgress.of(
      balanceCents: wallet.balanceCents,
      fundedCents: wallet.fundedCents,
      targetCents: wallet.targetCents,
      currency: wallet.currency,
    );
    return RingDial(
      size: 210,
      thickness: 16,
      dotted: true,
      progress: progress.fraction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            wallet.balance.format(),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          Text(
            progress.label,
            style: const TextStyle(fontSize: 12, color: CasheColors.muted),
          ),
        ],
      ),
    );
  }
}

class _Rules extends StatelessWidget {
  const _Rules({required this.wallet});

  final WalletDetail wallet;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Opens at', wallet.place.name),
      (
        'Stay',
        '${WalletText.dwell(wallet.place.dwellSeconds)} within ${wallet.place.radiusM} m',
      ),
      ('When', WalletText.windows(wallet.timeWindows)),
      if (wallet.status == WalletStatus.pending &&
          wallet.claimExpiresAt != null)
        (
          'If unclaimed',
          'Back to ${wallet.isFunder ? 'you' : wallet.funderName} ${WalletText.date(wallet.claimExpiresAt!)}',
        ),
      if (wallet.expiresAt != null)
        ('Expires', WalletText.date(wallet.expiresAt!)),
      if (wallet.status == WalletStatus.cancelled)
        ('Status', 'Cancelled and refunded'),
      if (wallet.status == WalletStatus.expired)
        ('Status', 'Expired and refunded'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            for (final (index, (label, value)) in rows.indexed)
              _RuleRow(
                label: label,
                value: value,
                last: index == rows.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.label,
    required this.value,
    required this.last,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: CasheColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: CasheColors.textBody),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.wallet});

  final WalletDetail wallet;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MonoLabel('History'),
        const SizedBox(height: 6),
        if (wallet.recentEntries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 11),
            child: Text(
              'Nothing yet.',
              style: TextStyle(color: CasheColors.muted),
            ),
          ),
        for (final entry in wallet.recentEntries) LedgerEntryTile(entry: entry),
        if (wallet.recentEntries.length >= 10)
          TextButton(
            onPressed: () => context.push('/wallets/${wallet.id}/history'),
            child: const Text('See all history'),
          ),
      ],
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.wallet});

  final WalletDetail wallet;

  bool get _open =>
      wallet.status == WalletStatus.active ||
      wallet.status == WalletStatus.pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (wallet.isOwner && wallet.status == WalletStatus.active)
          FilledButton(
            onPressed: () => context.push('/wallets/${wallet.id}/unlock'),
            child: const Text('Unlock'),
          ),
        if (wallet.isFunder && _open) ...[
          if (wallet.isOwner) const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => context.push('/add?wallet=${wallet.id}'),
            child: const Text('Add money'),
          ),
        ],
        if (wallet.kind == WalletKind.gift &&
            wallet.isFunder &&
            wallet.status == WalletStatus.pending)
          TextButton(
            onPressed: () => _cancel(context, ref),
            child: const Text('Cancel gift'),
          ),
      ],
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Cancel this gift?'),
        content: Text(
          'The link stops working and ${wallet.balance.format()} comes back to you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Cancel gift'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(walletActionsProvider).cancel(wallet.id);
    } catch (error) {
      if (context.mounted) showErrorSnackBar(context, error);
    }
  }
}
