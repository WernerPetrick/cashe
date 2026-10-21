import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../domain/ledger_entry.dart';
import '../../domain/wallet_text.dart';

/// One history row in the design's style: label on the left, amount on the right.
class LedgerEntryTile extends StatelessWidget {
  const LedgerEntryTile({super.key, required this.entry, this.walletName});

  final LedgerEntry entry;
  final String? walletName;

  String get _label => switch (entry.kind) {
    LedgerKind.deposit => 'Added',
    LedgerKind.spend => 'Spent at ${entry.placeName ?? 'the place'}',
    LedgerKind.refund => 'Refunded to sender',
  };

  @override
  Widget build(BuildContext context) {
    final detail = [?walletName, WalletText.date(entry.createdAt)].join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CasheColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: CasheColors.textSoft,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CasheColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.amountCents > 0 ? '+' : ''}${entry.amount.format()}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
