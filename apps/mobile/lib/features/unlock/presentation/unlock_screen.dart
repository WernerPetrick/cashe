import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/location/location_service.dart';
import '../../../core/widgets/cashe_widgets.dart';
import '../../../core/widgets/error_view.dart';
import '../../wallets/domain/wallet.dart';
import '../../wallets/presentation/wallet_providers.dart';
import '../domain/ping_outcome.dart';
import 'unlock_controller.dart';
import 'widgets/card_machine_sheet.dart';
import 'widgets/unlock_views.dart';

/// The only screen that uses location. Readings start after the user agrees and
/// stop when they leave (the controller is disposed with the screen).
class UnlockScreen extends ConsumerWidget {
  const UnlockScreen({super.key, required this.walletId});

  final int walletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletDetailProvider(walletId));
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          child: wallet.when(
            data: (detail) => _UnlockBody(wallet: detail),
            error: (error, _) => ErrorView(
              error: error,
              onRetry: () => ref.invalidate(walletDetailProvider(walletId)),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }
}

class _UnlockBody extends ConsumerWidget {
  const _UnlockBody({required this.wallet});

  final WalletDetail wallet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlock = ref.watch(unlockControllerProvider(wallet.id));
    final controller = ref.read(unlockControllerProvider(wallet.id).notifier);
    void leave() => Navigator.of(context).pop();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _phase(context, ref, unlock, controller, leave)),
        if (unlock.failure case final failure?)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              failure.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: CasheColors.warning),
            ),
          ),
      ],
    );
  }

  Widget _phase(
    BuildContext context,
    WidgetRef ref,
    UnlockState unlock,
    UnlockController controller,
    VoidCallback leave,
  ) {
    return switch (unlock.phase) {
      UnlockPhase.starting => _ask(
        'Check in at ${wallet.place.name}',
        LocationService.rationale,
        'Share my location',
        controller.start,
        leave,
      ),
      UnlockPhase.needsPermission => _ask(
        'Location is needed here',
        'Without it Cashe can’t tell you’re at ${wallet.place.name}. ${LocationService.rationale}',
        'Try again',
        controller.start,
        leave,
      ),
      UnlockPhase.permissionBlocked => _ask(
        'Location is turned off for Cashe',
        'Allow location “while using the app” in Settings, then come back.',
        'Open settings',
        controller.openSettings,
        leave,
      ),
      UnlockPhase.serviceOff => _ask(
        'Location services are off',
        'Turn on location on your device, then try again.',
        'Try again',
        controller.start,
        leave,
      ),
      UnlockPhase.tracking => _tracking(
        context,
        ref,
        unlock,
        controller,
        leave,
      ),
    };
  }

  Widget _ask(
    String title,
    String message,
    String action,
    VoidCallback onAction,
    VoidCallback onCancel,
  ) {
    return StatusLayout(
      ring: const LockedRing(),
      title: title,
      message: message,
      actions: [
        FilledButton(onPressed: onAction, child: Text(action)),
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
      ],
    );
  }

  Widget _tracking(
    BuildContext context,
    WidgetRef ref,
    UnlockState unlock,
    UnlockController controller,
    VoidCallback leave,
  ) {
    final outcome = unlock.outcome;
    final until = outcome?.unlockedUntil;
    if (unlock.lastSpend case final spend?) {
      return FillOrScroll(
        child: PaidView(
          wallet: wallet,
          spend: spend,
          unlockedUntil: until,
          onPayAgain: controller.dismissSpend,
          onDone: leave,
        ),
      );
    }
    if (outcome == null || outcome.status == PingStatus.dwelling) {
      return CheckingView(wallet: wallet, outcome: outcome, onCancel: leave);
    }
    if (outcome.status == PingStatus.unlocked && until != null) {
      return FillOrScroll(
        child: UnlockedView(
          wallet: wallet,
          unlockedUntil: until,
          paying: unlock.spending,
          onSimulateTap: () => _pay(context, ref, controller),
          onDone: leave,
        ),
      );
    }
    return StillLockedView(wallet: wallet, outcome: outcome, onBack: leave);
  }

  Future<void> _pay(
    BuildContext context,
    WidgetRef ref,
    UnlockController controller,
  ) async {
    final charge = await CardMachineSheet.show(
      context,
      currency: wallet.currency,
      balanceCents: wallet.balanceCents,
    );
    if (charge == null) return;
    final entry = await controller.spend(
      charge.cents,
      idempotencyKey: charge.key,
    );
    if (entry != null) ref.read(walletActionsProvider).refresh(wallet.id);
  }
}
