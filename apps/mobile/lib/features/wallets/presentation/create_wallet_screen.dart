import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/ids/idempotency_key.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/amount_display.dart';
import '../../../core/widgets/amount_keypad.dart';
import '../../../core/widgets/cashe_widgets.dart';
import '../../../core/widgets/error_view.dart';
import '../../places/domain/place.dart';
import '../domain/time_window.dart';
import '../domain/wallet.dart';
import 'wallet_providers.dart';
import 'widgets/create_place_step.dart';
import 'widgets/create_review_step.dart';

/// The design's three-step creator: amount, place, review. A goal ("Lock") is
/// mine; a gift ("Send") goes on to its one-time share link.
class CreateWalletScreen extends ConsumerStatefulWidget {
  const CreateWalletScreen({super.key, required this.kind});

  final WalletKind kind;

  @override
  ConsumerState<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends ConsumerState<CreateWalletScreen> {
  int _step = 1;
  String _typed = '0';
  String _currency = Money.currencies.first;
  Place? _place;
  String? _name;
  final List<TimeWindow> _windows = [];
  DateTime? _expiresAt;
  bool _saving = false;
  final _depositKey = newIdempotencyKey();

  bool get _isGift => widget.kind == WalletKind.gift;
  int? get _cents => Money.parseCents(_typed);

  void _back() => _step == 1 ? context.pop() : setState(() => _step--);

  Future<void> _confirm() async {
    final place = _place!;
    final cents = _cents!;
    setState(() => _saving = true);
    try {
      final actions = ref.read(walletActionsProvider);
      final wallet = await actions.create(_draft(place));
      await actions.topUp(wallet.id, cents, _depositKey);
      if (!mounted) return;
      _finish(wallet, Money(cents, _currency), place);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showErrorSnackBar(context, error);
    }
  }

  WalletDraft _draft(Place place) => WalletDraft(
    kind: widget.kind,
    name: (_name ?? '').trim().isEmpty ? place.name : _name!.trim(),
    placeId: place.id,
    currency: _currency,
    expiresAt: _isGift ? _expiresAt?.toUtc() : null,
    timeWindows: _windows,
  );

  void _finish(WalletDetail wallet, Money amount, Place place) {
    if (_isGift) {
      context.pushReplacement(
        '/wallets/${wallet.id}/gift-link',
        extra: wallet.claimUrl,
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Locked ${amount.format()} at ${place.name}')),
    );
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StepHeader(
                step: _step,
                backLabel: _step == 1 ? 'Cancel' : 'Back',
                onBack: _back,
              ),
              Expanded(child: _stepBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepBody() => switch (_step) {
    1 => _AmountStep(
      isGift: _isGift,
      typed: _typed,
      currency: _currency,
      onKey: (key) => setState(() => _typed = KeypadInput.press(_typed, key)),
      onCurrency: (code) => setState(() => _currency = code),
      onNext: _cents == null ? null : () => setState(() => _step = 2),
    ),
    2 => CreatePlaceStep(
      amount: Money(_cents ?? 0, _currency),
      selected: _place,
      onPick: (place) => setState(() => _place = place),
      onNext: _place == null ? null : () => setState(() => _step = 3),
    ),
    _ => CreateReviewStep(
      isGift: _isGift,
      amount: Money(_cents ?? 0, _currency),
      place: _place!,
      name: _name ?? _place!.name,
      windows: _windows,
      expiresAt: _expiresAt,
      saving: _saving,
      onName: (name) => setState(() => _name = name),
      onAddWindow: (window) => setState(() => _windows.add(window)),
      onRemoveWindow: (index) => setState(() => _windows.removeAt(index)),
      onExpiry: (expiry) => setState(() => _expiresAt = expiry),
      onConfirm: _confirm,
    ),
  };
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.step,
    required this.backLabel,
    required this.onBack,
  });

  final int step;
  final String backLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: PillButton(label: backLabel, onPressed: onBack),
            ),
            MonoLabel('Step $step of 3'),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: step / 3,
            minHeight: 3,
            backgroundColor: CasheColors.divider,
          ),
        ),
      ],
    );
  }
}

class _AmountStep extends StatelessWidget {
  const _AmountStep({
    required this.isGift,
    required this.typed,
    required this.currency,
    required this.onKey,
    required this.onCurrency,
    required this.onNext,
  });

  final bool isGift;
  final String typed;
  final String currency;
  final ValueChanged<String> onKey;
  final ValueChanged<String> onCurrency;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text(
          isGift ? 'How much to give?' : 'How much to lock?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 36),
        AmountDisplay(typed: typed, currency: currency, size: 52),
        const SizedBox(height: 10),
        Center(
          child: Wrap(
            spacing: 6,
            children: [
              for (final code in Money.currencies)
                ChoiceChip(
                  label: Text(code),
                  selected: code == currency,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: code == currency
                        ? CasheColors.background
                        : CasheColors.text,
                  ),
                  onSelected: (_) => onCurrency(code),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Simulated money: no real payment is taken.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: CasheColors.muted),
        ),
        const Spacer(),
        AmountKeypad(onKey: onKey),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: onNext,
          child: const Text('Next: choose place'),
        ),
      ],
    );
  }
}
