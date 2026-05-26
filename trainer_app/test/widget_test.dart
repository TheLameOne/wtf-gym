import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  group('SessionLogModel', () {
    test('calculateDuration returns correct seconds between two DateTimes', () {
      final start = DateTime(2025, 1, 1, 10, 0, 0);
      final end = DateTime(2025, 1, 1, 10, 30, 45);
      final secs = SessionLogModel.calculateDuration(start, end);
      expect(secs, 1845); // 30 min 45 sec
    });

    test('calculateDuration returns 0 when end equals start', () {
      final dt = DateTime(2025, 1, 1, 12, 0, 0);
      expect(SessionLogModel.calculateDuration(dt, dt), 0);
    });

    test('toSessionDuration extension formats correctly', () {
      expect(1845.toSessionDuration(), '30m 45s');
    });

    test('toSessionDuration handles zero duration', () {
      expect(0.toSessionDuration(), '0s');
    });
  });

  group('CallRequestModel', () {
    test('status helpers work correctly', () {
      final base = CallRequestModel(
        id: 'r1',
        memberId: 'member_dk',
        trainerId: 'trainer_aarav',
        requestedAt: DateTime(2025, 1, 1),
        scheduledFor: DateTime(2025, 1, 2),
        status: 'pending',
        memberName: 'DK',
        trainerName: 'Aarav',
      );

      expect(base.isPending, true);
      expect(base.isApproved, false);

      final approved = base.copyWith(status: 'approved');
      expect(approved.isApproved, true);
      expect(approved.isPending, false);

      final declined = base.copyWith(status: 'declined', declineReason: 'Busy');
      expect(declined.isDeclined, true);
      expect(declined.declineReason, 'Busy');
    });
  });
}
