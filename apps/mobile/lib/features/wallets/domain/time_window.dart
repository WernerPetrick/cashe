import 'package:freezed_annotation/freezed_annotation.dart';

part 'time_window.freezed.dart';
part 'time_window.g.dart';

/// A weekly window when a wallet may unlock, e.g. weekdays 10:30–11:00.
/// Days are 0 = Sunday … 6 = Saturday; times are "HH:MM", end exclusive.
@freezed
abstract class TimeWindow with _$TimeWindow {
  const factory TimeWindow({
    required List<int> daysOfWeek,
    required String startsAt,
    required String endsAt,
    required String timeZone,
  }) = _TimeWindow;

  factory TimeWindow.fromJson(Map<String, dynamic> json) =>
      _$TimeWindowFromJson(json);
}
