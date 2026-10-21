import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/cashe_widgets.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../wallets/domain/pot_progress.dart';
import '../../wallets/domain/wallet.dart';
import '../../wallets/domain/wallet_text.dart';
import '../../wallets/presentation/wallet_providers.dart';

/// Home from the design: greeting, total balance, quick actions and "Your pots".
/// Pots are the wallets I own (my goals and gifts I've claimed); gifts I've sent
/// to other people are listed separately.
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsProvider);
    return wallets.when(
      data: (list) => RefreshIndicator(
        onRefresh: () => ref.refresh(walletsProvider.future),
        child: _HomeList(wallets: list),
      ),
      error: (error, _) => ErrorView(
        error: error,
        onRetry: () => ref.invalidate(walletsProvider),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class _HomeList extends StatelessWidget {
  const _HomeList({required this.wallets});

  final List<Wallet> wallets;

  @override
  Widget build(BuildContext context) {
    final pots = wallets
        .where(
          (wallet) =>
              wallet.role == WalletRole.owner &&
              wallet.status == WalletStatus.active,
        )
        .toList();
    final sent = wallets
        .where(
          (wallet) =>
              wallet.role == WalletRole.funder &&
              wallet.kind == WalletKind.gift,
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
      children: [
        const _Greeting(),
        const SizedBox(height: 22),
        _Totals(pots: pots, sentCount: sent.length),
        const SizedBox(height: 22),
        const _QuickActions(),
        const SizedBox(height: 22),
        _Section(
          title: 'Your pots',
          trailing: '${pots.length} ${pots.length == 1 ? 'pot' : 'pots'}',
        ),
        if (pots.isEmpty)
          const _Empty(
            'Nothing locked yet. Tap Lock to save for a place, or claim a gift someone sent you.',
          ),
        for (final pot in pots) _PotRow(wallet: pot),
        if (sent.isNotEmpty) ...[
          const SizedBox(height: 22),
          _Section(title: 'Gifts you sent', trailing: '${sent.length}'),
          for (final gift in sent) _PotRow(wallet: gift),
        ],
      ],
    );
  }
}

class _Greeting extends ConsumerWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(authControllerProvider).value?.displayName ?? '';
    final first = name.split(' ').first;
    return Row(
      children: [
        const CasheLogo(),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Hi $first',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: CasheColors.textSoft,
            ),
          ),
        ),
        CircleAvatar(
          radius: 18,
          backgroundColor: CasheColors.track,
          child: Text(
            first.isEmpty ? '?' : first[0].toUpperCase(),
            style: const TextStyle(
              color: CasheColors.amber,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.pots, required this.sentCount});

  final List<Wallet> pots;
  final int sentCount;

  /// Totals per currency; the most-used currency is the headline.
  List<Money> get _totals {
    final cents = <String, int>{};
    for (final pot in pots) {
      cents[pot.currency] = (cents[pot.currency] ?? 0) + pot.balanceCents;
    }
    final totals = [
      for (final entry in cents.entries) Money(entry.value, entry.key),
    ];
    totals.sort((a, b) => b.cents.compareTo(a.cents));
    return totals.isEmpty ? [const Money(0, 'ZAR')] : totals;
  }

  @override
  Widget build(BuildContext context) {
    final totals = _totals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MonoLabel('Total balance'),
        const SizedBox(height: 12),
        Text(
          totals.first.format(),
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final other in totals.skip(1)) _Chip(other.format()),
            _Chip(
              '${pots.length} locked ${pots.length == 1 ? 'pot' : 'pots'}',
              amber: true,
            ),
            if (sentCount > 0) _Chip('$sentCount sent as gifts'),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, {this.amber = false});

  final String text;
  final bool amber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: amber ? CasheColors.amber : null,
        border: amber ? null : Border.all(color: CasheColors.outline),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: amber ? FontWeight.w700 : FontWeight.w600,
          color: amber ? CasheColors.background : CasheColors.textSoft,
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    Widget action(String label, String route) => Expanded(
      child: OutlinedButton(
        onPressed: () => context.push(route),
        style: OutlinedButton.styleFrom(
          backgroundColor: CasheColors.surface,
          side: const BorderSide(color: CasheColors.border),
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(label),
      ),
    );
    return Row(
      children: [
        action('Add', '/add'),
        const SizedBox(width: 10),
        action('Send', '/wallets/new/gift'),
        const SizedBox(width: 10),
        action('Lock', '/wallets/new/goal'),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          Text(
            trailing,
            style: const TextStyle(fontSize: 13, color: CasheColors.muted),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Text(text, style: const TextStyle(color: CasheColors.muted)),
  );
}

class _PotRow extends StatelessWidget {
  const _PotRow({required this.wallet});

  final Wallet wallet;

  String get _subtitle {
    final people = WalletText.people(
      kind: wallet.kind,
      role: wallet.role,
      status: wallet.status,
      funderName: wallet.funderName,
      ownerName: wallet.ownerName,
    );
    return [
      wallet.place.name,
      if (people != null) people.replaceFirst('From ', 'from '),
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final progress = PotProgress.of(
      balanceCents: wallet.balanceCents,
      fundedCents: wallet.fundedCents,
      targetCents: wallet.targetCents,
      currency: wallet.currency,
    );
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/wallets/${wallet.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        child: Row(
          children: [
            RingDial(size: 40, thickness: 5, progress: progress.fraction),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: CasheColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              wallet.balance.format(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
