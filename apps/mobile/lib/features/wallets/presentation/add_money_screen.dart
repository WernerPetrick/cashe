import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/ids/idempotency_key.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/amount_display.dart';
import '../../../core/widgets/amount_keypad.dart';
import '../../../core/widgets/cashe_widgets.dart';
import '../../../core/widgets/error_view.dart';
import '../domain/wallet.dart';
import 'wallet_providers.dart';

/// "Add money" from the design: a simulated top-up into one of the pots I fund.
class AddMoneyScreen extends ConsumerStatefulWidget {
  const AddMoneyScreen({super.key, this.walletId});

  /// Pre-selects this pot (when opened from a pot's page).
  final int? walletId;

  @override
  ConsumerState<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends ConsumerState<AddMoneyScreen> {
  String _typed = '0';
  int? _selected;
  bool _saving = false;
  ({int cents, int walletId, String key})? _attempt;

  @override
  void initState() {
    super.initState();
    _selected = widget.walletId;
  }

  /// Pots I can top up: my goals and the gifts I'm funding that are still open.
  List<Wallet> _targets(List<Wallet> wallets) => wallets
      .where(
        (wallet) =>
            wallet.role == WalletRole.funder || wallet.kind == WalletKind.goal,
      )
      .where(
        (wallet) =>
            wallet.status == WalletStatus.active ||
            wallet.status == WalletStatus.pending,
      )
      .toList();

  Future<void> _add(Wallet wallet) async {
    final cents = Money.parseCents(_typed);
    if (cents == null) return;
    final same = _attempt?.cents == cents && _attempt?.walletId == wallet.id;
    final attempt = same
        ? _attempt!
        : (cents: cents, walletId: wallet.id, key: newIdempotencyKey());
    setState(() {
      _attempt = attempt;
      _saving = true;
    });
    try {
      await ref
          .read(walletActionsProvider)
          .topUp(wallet.id, cents, attempt.key);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${Money(cents, wallet.currency).format()} to ${wallet.name}',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletsProvider).value ?? const <Wallet>[];
    final targets = _targets(wallets);
    final chosen =
        targets.where((wallet) => wallet.id == _selected).firstOrNull ??
        targets.firstOrNull;
    final cents = Money.parseCents(_typed);
    final currency = chosen?.currency ?? Money.currencies.first;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PillButton(
                label: 'Cancel',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 20),
              Text(
                'Add money',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              AmountDisplay(typed: _typed, currency: currency),
              const SizedBox(height: 18),
              const _FromRow(),
              const SizedBox(height: 16),
              const Text(
                'Put it in',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CasheColors.textSoft,
                ),
              ),
              const SizedBox(height: 8),
              _PotChoices(
                targets: targets,
                selected: chosen?.id,
                onPick: (id) => setState(() => _selected = id),
              ),
              const Spacer(),
              AmountKeypad(
                onKey: (key) =>
                    setState(() => _typed = KeypadInput.press(_typed, key)),
                keyHeight: 50,
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: cents == null || chosen == null || _saving
                    ? null
                    : () => _add(chosen),
                child: Text(
                  cents == null
                      ? 'Add money'
                      : 'Add ${Money(cents, currency).format()}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FromRow extends StatelessWidget {
  const _FromRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: CasheColors.surface,
        border: Border.all(color: CasheColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Text(
            'From',
            style: TextStyle(fontSize: 14, color: CasheColors.textBody),
          ),
          Spacer(),
          Text(
            'Simulated bank',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PotChoices extends StatelessWidget {
  const _PotChoices({
    required this.targets,
    required this.selected,
    required this.onPick,
  });

  final List<Wallet> targets;
  final int? selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    if (targets.isEmpty) {
      return const Text(
        'No pots to top up yet. Lock some money or send a gift first.',
        style: TextStyle(color: CasheColors.muted),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final wallet in targets)
          ChoiceChip(
            label: Text(wallet.name),
            selected: wallet.id == selected,
            showCheckmark: false,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: wallet.id == selected
                  ? CasheColors.background
                  : CasheColors.text,
            ),
            onSelected: (_) => onPick(wallet.id),
          ),
      ],
    );
  }
}
