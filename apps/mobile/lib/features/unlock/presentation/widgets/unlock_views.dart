import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/money/money.dart';
import '../../../../core/widgets/cashe_widgets.dart';
import '../../../wallets/domain/ledger_entry.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/domain/wallet_text.dart';
import '../../domain/ping_outcome.dart';

/// A centred status screen with a ring on top, a title, a line of text and
/// buttons at the bottom: the layout every unlock state in the design shares.
class StatusLayout extends StatelessWidget {
  const StatusLayout({
    super.key,
    required this.ring,
    required this.title,
    this.message,
    this.actions = const [],
  });

  final Widget ring;
  final String title;
  final String? message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return FillOrScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Center(child: ring),
          const SizedBox(height: 34),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          if (message case final text?) ...[
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: CasheColors.textBody,
              ),
            ),
          ],
          const Spacer(),
          for (final (index, action) in actions.indexed) ...[
            if (index > 0) const SizedBox(height: 10),
            action,
          ],
        ],
      ),
    );
  }
}

/// An empty ring with a hollow centre: locked.
class LockedRing extends StatelessWidget {
  const LockedRing({super.key});

  @override
  Widget build(BuildContext context) => RingDial(
    size: 190,
    thickness: 14,
    progress: 0,
    child: Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: CasheColors.faint, width: 3),
      ),
    ),
  );
}

/// "Checking you're at X": the ring fills over the place's dwell time.
/// Before the first answer it spins.
class CheckingView extends StatelessWidget {
  const CheckingView({
    super.key,
    required this.wallet,
    required this.outcome,
    required this.onCancel,
  });

  final WalletDetail wallet;
  final PingOutcome? outcome;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final current = outcome;
    final required = current?.dwellRequiredSeconds ?? wallet.place.dwellSeconds;
    final dot = Container(
      width: 54,
      height: 54,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: CasheColors.amber,
      ),
    );
    final ring = current == null
        ? SizedBox.square(
            dimension: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox.expand(
                  child: CircularProgressIndicator(
                    strokeWidth: 14,
                    backgroundColor: CasheColors.track,
                  ),
                ),
                dot,
              ],
            ),
          )
        : RingDial(
            size: 190,
            thickness: 14,
            progress: current.dwellProgressSeconds / required,
            child: dot,
          );
    return StatusLayout(
      key: Key(
        current == null ? 'ping-status-locating' : 'ping-status-dwelling',
      ),
      ring: ring,
      title: 'Checking you’re at ${wallet.place.name}',
      message: current == null
          ? 'Finding your location…'
          : 'Stay here · ${required - current.dwellProgressSeconds} s to go',
      actions: [TextButton(onPressed: onCancel, child: const Text('Cancel'))],
    );
  }
}

/// "Still locked": outside the zone, outside the hours, or a rejected fix.
/// Pings keep running, so it unlocks by itself once things are right.
class StillLockedView extends StatelessWidget {
  const StillLockedView({
    super.key,
    required this.wallet,
    required this.outcome,
    required this.onBack,
  });

  final WalletDetail wallet;
  final PingOutcome outcome;
  final VoidCallback onBack;

  (String, String, String) get _wording => switch (outcome.status) {
    PingStatus.outsideTimeWindow => (
      'outside_time_window',
      'Outside the allowed times',
      'This pot opens at ${wallet.place.name} ${WalletText.windows(wallet.timeWindows)}.',
    ),
    PingStatus.rejected when outcome.reason == RejectionReason.mockLocation => (
      'rejected',
      'Location rejected',
      'Cashe can’t use a mock (fake) location. Turn off any location-spoofing app.',
    ),
    PingStatus.rejected => (
      'rejected',
      'Location not precise enough',
      'Move to where your phone can see the sky, or wait a moment.',
    ),
    _ => (
      'outside_zone',
      'Still locked',
      'This pot opens at ${wallet.place.name}. Get within ${wallet.place.radiusM} m and it unlocks by itself.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (key, title, message) = _wording;
    return StatusLayout(
      key: Key('ping-status-$key'),
      ring: const LockedRing(),
      title: title,
      message: message,
      actions: [
        OutlinedButton(onPressed: onBack, child: const Text('Back to pot')),
      ],
    );
  }
}

/// Unlocked: the amber card, "tap your phone" and a live relock countdown.
class UnlockedView extends StatefulWidget {
  const UnlockedView({
    super.key,
    required this.wallet,
    required this.unlockedUntil,
    required this.paying,
    required this.onSimulateTap,
    required this.onDone,
  });

  final WalletDetail wallet;
  final DateTime unlockedUntil;
  final bool paying;
  final VoidCallback onSimulateTap;
  final VoidCallback onDone;

  @override
  State<UnlockedView> createState() => _UnlockedViewState();
}

class _UnlockedViewState extends State<UnlockedView> {
  late final Timer _tick = Timer.periodic(
    const Duration(seconds: 1),
    (_) => setState(() {}),
  );

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  String get _relocksIn {
    final left = widget.unlockedUntil.difference(DateTime.now());
    final seconds = left.isNegative ? 0 : left.inSeconds;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('ping-status-unlocked'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        const Center(child: MonoLabel('Unlocked', color: CasheColors.amber)),
        const SizedBox(height: 16),
        Center(child: _AmberCard(wallet: widget.wallet)),
        const Spacer(),
        Center(
          child: PulseRings(
            size: 150,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CasheColors.surface,
                border: Border.all(color: CasheColors.amber, width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Tap your phone on the card machine',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Relocks in $_relocksIn if unused',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13.5, color: CasheColors.muted),
        ),
        const Spacer(),
        _SimulateTapButton(
          paying: widget.paying,
          onPressed: widget.onSimulateTap,
        ),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: widget.onDone, child: const Text('Done')),
      ],
    );
  }
}

class _AmberCard extends StatelessWidget {
  const _AmberCard({required this.wallet});

  final WalletDetail wallet;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: AspectRatio(
        aspectRatio: 1.6,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: CasheColors.amber,
            borderRadius: BorderRadius.circular(20),
          ),
          child: DefaultTextStyle(
            style: const TextStyle(
              fontFamily: 'Manrope',
              color: CasheColors.background,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        wallet.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const CasheLogo(size: 28),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available to spend',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      wallet.balance.format(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SimulateTapButton extends StatelessWidget {
  const _SimulateTapButton({required this.paying, required this.onPressed});

  final bool paying;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: paying ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        side: const BorderSide(color: CasheColors.dots),
        foregroundColor: CasheColors.textSoft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontFamily: mono,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
      child: Text(paying ? 'PAYING…' : 'PROTOTYPE · SIMULATE CARD TAP'),
    );
  }
}

/// Paid: the amount, where, and what's left in the pot.
class PaidView extends StatelessWidget {
  const PaidView({
    super.key,
    required this.wallet,
    required this.spend,
    required this.unlockedUntil,
    required this.onPayAgain,
    required this.onDone,
  });

  final WalletDetail wallet;
  final LedgerEntry spend;
  final DateTime? unlockedUntil;
  final VoidCallback onPayAgain;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final until = unlockedUntil;
    return Column(
      key: const Key('unlock-paid'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Center(
          child: RingDial(
            size: 130,
            thickness: 14,
            progress: 1,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: CasheColors.amber,
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          Money(-spend.amountCents, spend.currency).format(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Paid at ${wallet.place.name}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: CasheColors.textSoft),
        ),
        const SizedBox(height: 30),
        _LeftInPot(balance: wallet.balance),
        const SizedBox(height: 10),
        Text(
          until == null
              ? 'Locked again.'
              : 'Spendable again until ${WalletText.clock(until)}, then it locks.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: CasheColors.muted),
        ),
        const Spacer(),
        if (until != null && until.isAfter(DateTime.now()))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              onPressed: onPayAgain,
              child: const Text('Pay again'),
            ),
          ),
        FilledButton(onPressed: onDone, child: const Text('Done')),
      ],
    );
  }
}

class _LeftInPot extends StatelessWidget {
  const _LeftInPot({required this.balance});

  final Money balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: CasheColors.surface,
        border: Border.all(color: CasheColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text(
            'Left in pot',
            style: TextStyle(fontSize: 14, color: CasheColors.textSoft),
          ),
          const Spacer(),
          Text(
            balance.format(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
