import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/cashe_widgets.dart';
import '../../domain/pot_progress.dart';
import '../../domain/wallet.dart';
import '../../domain/wallet_text.dart';

class SpotRow extends StatelessWidget {
  const SpotRow({super.key, required this.wallet});

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
