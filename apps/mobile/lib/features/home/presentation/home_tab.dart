import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/cashe_widgets.dart';
import '../../../core/widgets/error_view.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../wallets/domain/wallet.dart';
import '../../wallets/presentation/wallet_providers.dart';
import '../../wallets/presentation/widgets/spot_row.dart';

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
    final spots = wallets
        .where(
          (wallet) =>
              wallet.role == WalletRole.owner &&
              wallet.status == WalletStatus.active,
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
      children: [
        const _Greeting(),
        const SizedBox(height: 22),
        const _StartActions(),
        const SizedBox(height: 26),
        _Section(
          title: 'Your spots',
          trailing: '${spots.length} ${spots.length == 1 ? 'spot' : 'spots'}',
        ),
        if (spots.isEmpty)
          const _Empty(
            'No spots yet. Start one to save for a place, or claim a gift someone sent you.',
          ),
        for (final spot in spots) SpotRow(wallet: spot),
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

class _StartActions extends StatelessWidget {
  const _StartActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => context.push('/wallets/new/goal'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            icon: const Icon(Icons.add),
            label: const Text('New spot'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/wallets/new/gift'),
            style: OutlinedButton.styleFrom(
              backgroundColor: CasheColors.surface,
              side: const BorderSide(color: CasheColors.border),
              minimumSize: const Size.fromHeight(56),
            ),
            icon: const Icon(Icons.card_giftcard),
            label: const Text('Send cash'),
          ),
        ),
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
