import 'package:cashe/features/unlock/domain/ping_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads every rejection reason the API sends', () {
    const reasons = {
      'mock_location': RejectionReason.mockLocation,
      'low_accuracy': RejectionReason.lowAccuracy,
      'impossible_jump': RejectionReason.impossibleJump,
    };
    for (final MapEntry(key: json, value: reason) in reasons.entries) {
      final outcome = PingOutcome.fromJson({
        'status': 'rejected',
        'inside_zone': null,
        'in_time_window': null,
        'dwell_progress_seconds': 0,
        'dwell_required_seconds': null,
        'unlocked_until': null,
        'reason': json,
      });
      expect(outcome.reason, reason);
    }
  });
}
