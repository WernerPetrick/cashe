import 'package:intl/intl.dart';

import 'time_window.dart';
import 'wallet.dart';

/// Human wording for wallet rules and relationships, kept out of widgets so it
/// can be tested.
abstract final class WalletText {
  static const _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  /// [1,2,3,4,5] → "Mon–Fri"; [0,6] → "Sun, Sat"; [3] → "Wed".
  static String days(List<int> days) {
    final sorted = [...days]..sort();
    final runs = <List<int>>[];
    for (final day in sorted) {
      if (runs.isNotEmpty && runs.last.last == day - 1) {
        runs.last.add(day);
      } else {
        runs.add([day]);
      }
    }
    return runs.map(_run).join(', ');
  }

  static String _run(List<int> run) => run.length >= 3
      ? '${_dayNames[run.first]}–${_dayNames[run.last]}'
      : run.map((day) => _dayNames[day]).join(', ');

  static String window(TimeWindow window) =>
      '${days(window.daysOfWeek)} ${window.startsAt}–${window.endsAt}';

  static String windows(List<TimeWindow> windows) =>
      windows.isEmpty ? 'Any time' : windows.map(window).join(' · ');

  /// "From Pat", "Claimed by Sam", "Waiting to be claimed", or null for goals.
  static String? people({
    required WalletKind kind,
    required WalletRole role,
    required WalletStatus status,
    required String funderName,
    String? ownerName,
  }) {
    if (kind == WalletKind.goal) return null;
    if (role == WalletRole.owner) return 'From $funderName';
    return switch (status) {
      WalletStatus.pending => 'Waiting to be claimed',
      WalletStatus.cancelled => 'Cancelled',
      WalletStatus.expired =>
        ownerName == null ? 'Not claimed — refunded' : 'Expired — refunded',
      WalletStatus.active => 'Claimed by ${ownerName ?? 'someone'}',
    };
  }

  static String date(DateTime time) =>
      DateFormat('EEE d MMM, HH:mm').format(time.toLocal());

  static String clock(DateTime time) =>
      DateFormat('HH:mm').format(time.toLocal());

  static String dwell(int seconds) => seconds < 60
      ? '$seconds s'
      : '${seconds ~/ 60} min${seconds % 60 == 0 ? '' : ' ${seconds % 60} s'}';
}
