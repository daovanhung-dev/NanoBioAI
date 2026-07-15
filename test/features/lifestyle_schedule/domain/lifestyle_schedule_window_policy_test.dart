import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/services/lifestyle_schedule_window_policy.dart';

void main() {
  test('parses supported SQLite and Supabase time formats', () {
    expect(
      LifestyleScheduleWindowPolicy.parseScheduledAt(
        scheduleDate: '2026-07-13',
        startTime: '07:05',
      ),
      DateTime(2026, 7, 13, 7, 5),
    );
    expect(
      LifestyleScheduleWindowPolicy.parseScheduledAt(
        scheduleDate: '2026-07-13',
        startTime: '07:05:09',
      ),
      DateTime(2026, 7, 13, 7, 5, 9),
    );
    expect(
      LifestyleScheduleWindowPolicy.parseScheduledAt(
        scheduleDate: '2026-07-13',
        startTime: '07:05:09.123456',
      ),
      DateTime(2026, 7, 13, 7, 5, 9, 123, 456),
    );
  });

  test('invalid date or time fails closed', () {
    for (final input in ['7:05', '24:00', '07:60', '07:05:60', 'text']) {
      expect(
        LifestyleScheduleWindowPolicy.statusAt(
          scheduleDate: '2026-07-13',
          startTime: input,
          isCompleted: false,
          now: DateTime(2026, 7, 13, 7, 10),
        ),
        CompletionWindowStatus.locked,
      );
    }
    expect(
      LifestyleScheduleWindowPolicy.parseScheduledAt(
        scheduleDate: '2026-02-30',
        startTime: '07:05',
      ),
      isNull,
    );
  });

  test('window includes the exact 30 minute deadline', () {
    CompletionWindowStatus statusAt(DateTime now) {
      return LifestyleScheduleWindowPolicy.statusAt(
        scheduleDate: '2026-07-13',
        startTime: '07:00:00',
        isCompleted: false,
        now: now,
      );
    }

    expect(
      statusAt(DateTime(2026, 7, 13, 6, 59, 59)),
      CompletionWindowStatus.waiting,
    );
    expect(statusAt(DateTime(2026, 7, 13, 7)), CompletionWindowStatus.open);
    expect(
      statusAt(DateTime(2026, 7, 13, 7, 29, 59, 999)),
      CompletionWindowStatus.open,
    );
    expect(statusAt(DateTime(2026, 7, 13, 7, 30)), CompletionWindowStatus.open);
    expect(
      statusAt(DateTime(2026, 7, 13, 7, 30, 0, 1)),
      CompletionWindowStatus.locked,
    );
  });

  test('UTC instant is converted to Vietnam wall clock', () {
    expect(
      LifestyleScheduleWindowPolicy.statusAt(
        scheduleDate: '2026-07-13',
        startTime: '07:00',
        isCompleted: false,
        now: DateTime.utc(2026, 7, 13, 0, 15),
      ),
      CompletionWindowStatus.open,
    );
  });
}
