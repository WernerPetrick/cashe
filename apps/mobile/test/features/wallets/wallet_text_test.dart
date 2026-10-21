import 'package:cashe/features/wallets/domain/time_window.dart';
import 'package:cashe/features/wallets/domain/wallet.dart';
import 'package:cashe/features/wallets/domain/wallet_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('collapses runs of three or more days', () {
    expect(WalletText.days([1, 2, 3, 4, 5]), 'Mon–Fri');
    expect(WalletText.days([0, 6]), 'Sun, Sat');
    expect(WalletText.days([1, 2, 4, 5, 6]), 'Mon, Tue, Thu–Sat');
  });

  test('describes windows, or any time without them', () {
    const recess = TimeWindow(
      daysOfWeek: [1, 2, 3, 4, 5],
      startsAt: '10:30',
      endsAt: '11:00',
      timeZone: 'Africa/Johannesburg',
    );
    expect(WalletText.windows([recess]), 'Mon–Fri 10:30–11:00');
    expect(WalletText.windows([]), 'Any time');
  });

  group('people', () {
    String? people(WalletRole role, WalletStatus status, {String? owner}) =>
        WalletText.people(
          kind: WalletKind.gift,
          role: role,
          status: status,
          funderName: 'Pat',
          ownerName: owner,
        );

    test('the recipient sees who it is from', () {
      expect(
        people(WalletRole.owner, WalletStatus.active, owner: 'Sam'),
        'From Pat',
      );
    });

    test('the funder sees who claimed it', () {
      expect(
        people(WalletRole.funder, WalletStatus.active, owner: 'Sam'),
        'Claimed by Sam',
      );
      expect(
        people(WalletRole.funder, WalletStatus.pending),
        'Waiting to be claimed',
      );
    });

    test('goals have no people line', () {
      expect(
        WalletText.people(
          kind: WalletKind.goal,
          role: WalletRole.owner,
          status: WalletStatus.active,
          funderName: 'Pat',
        ),
        isNull,
      );
    });
  });

  test('formats dwell times', () {
    expect(WalletText.dwell(30), '30 s');
    expect(WalletText.dwell(120), '2 min');
    expect(WalletText.dwell(90), '1 min 30 s');
  });
}
