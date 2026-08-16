import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/lifestyle_schedule_item_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/schedule_completion_proof_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_item_detail_page.dart';

void main() {
  testWidgets('detail shows full task information and completion CTA while open', (
    tester,
  ) async {
    var completeTapCount = 0;
    const description =
        'Mô tả chi tiết đủ dài để bảo đảm màn hình không cắt nội dung của nhiệm vụ.';
    final item = _item(description: description);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LifestyleScheduleItemDetailContent(
            item: item,
            proof: null,
            now: DateTime(2026, 8, 16, 12, 40),
            isSubmitting: false,
            onComplete: () => completeTapCount++,
          ),
        ),
      ),
    );

    expect(find.text('Ăn trưa đủ chất'), findsOneWidget);
    expect(find.text(description), findsOneWidget);
    expect(find.text('Đang đến giờ'), findsOneWidget);
    expect(find.text('12:30 – 13:15'), findsWidgets);
    expect(find.text('Hoàn thành nhiệm vụ'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('schedule-detail-complete-button')));
    await tester.pump();
    expect(completeTapCount, 1);
  });

  testWidgets('detail disables completion before the task starts', (tester) async {
    final item = _item(startTime: '13:15', endTime: '13:45');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LifestyleScheduleItemDetailContent(
            item: item,
            proof: null,
            now: DateTime(2026, 8, 16, 12, 40),
            isSubmitting: false,
            onComplete: null,
          ),
        ),
      ),
    );

    expect(find.text('Sắp tới'), findsOneWidget);
    expect(find.text('Chưa đến giờ thực hiện'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('schedule-detail-complete-button')),
    );
    expect(button.onPressed, isNull);
  });


  testWidgets('detail remains usable with larger text scale', (tester) async {
    final item = _item(
      description:
          'Nội dung chi tiết cần tự xuống dòng khi người dùng tăng kích thước chữ.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: Scaffold(
            body: LifestyleScheduleItemDetailContent(
              item: item,
              proof: null,
              now: DateTime(2026, 8, 16, 12, 40),
              isSubmitting: false,
              onComplete: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Ăn trưa đủ chất'), findsOneWidget);
  });

  testWidgets('confirmed reward is shown as plus ten care points', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleRewardStatusSummary(
            proof: _proof(rewardStatus: ScheduleProofRewardStatuses.confirmed),
          ),
        ),
      ),
    );

    expect(find.text('Điểm chăm sóc'), findsOneWidget);
    expect(find.text('+10 Điểm chăm sóc đã được đồng bộ.'), findsOneWidget);
  });

  testWidgets('pending reward never looks confirmed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleRewardStatusSummary(
            proof: _proof(rewardStatus: ScheduleProofRewardStatuses.pending),
          ),
        ),
      ),
    );

    expect(find.text('10 Điểm chăm sóc đang chờ đồng bộ.'), findsOneWidget);
    expect(find.text('+10 Điểm chăm sóc đã được đồng bộ.'), findsNothing);
  });
}

LifestyleScheduleItemEntity _item({
  String startTime = '12:30',
  String endTime = '13:15',
  String description = 'Bữa trưa cân bằng theo kế hoạch cá nhân.',
}) {
  return LifestyleScheduleItemEntity(
    id: 'lunch-1',
    userId: 'user-1',
    scheduleDate: '2026-08-16',
    startTime: startTime,
    endTime: endTime,
    title: 'Ăn trưa đủ chất',
    description: description,
    category: LifestyleScheduleCategories.meal,
    sourceType: LifestyleScheduleSourceTypes.mealPlan,
    sourceId: 'meal-1',
    targetValue: 1,
    currentValue: 0,
    unit: 'lan',
    encouragement: 'Ăn chậm và chú ý cảm giác no của cơ thể nhé.',
  );
}

ScheduleCompletionProofEntity _proof({required String rewardStatus}) {
  return ScheduleCompletionProofEntity(
    id: 'proof-1',
    userId: 'user-1',
    scheduleItemId: 'lunch-1',
    rewardEligibilityId: 'eligibility-1',
    completionAttemptId: 'attempt-1',
    scheduleDate: '2026-08-16',
    startTime: '12:30',
    scheduleTitle: 'Ăn trưa đủ chất',
    localPath: 'schedule_proofs/lunch.jpg',
    capturedAt: '2026-08-16T12:35:00+07:00',
    completedAt: '2026-08-16T12:36:00+07:00',
    cloudObjectPath: 'user-1/eligibility-1/attempt-1.jpg',
    uploadStatus: ScheduleProofUploadStatuses.uploaded,
    rewardStatus: rewardStatus,
    createdAt: '2026-08-16T12:36:00+07:00',
    updatedAt: '2026-08-16T12:36:00+07:00',
  );
}
