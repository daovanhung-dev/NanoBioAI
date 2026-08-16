import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/lifestyle_schedule_item_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/lifestyle_schedule_summary_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/presentation/controllers/lifestyle_schedule_state.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/presentation/widgets/schedule_date_selector.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/presentation/widgets/schedule_day_header.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/presentation/widgets/schedule_item_card.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/presentation/widgets/schedule_progress_summary.dart';

void main() {
  testWidgets('schedule header keeps date and completion summary glanceable', (
    tester,
  ) async {
    final state = _state(
      items: [
        _item(id: 'breakfast', startTime: '08:00', isCompleted: true),
        _item(id: 'water', startTime: '09:00'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleDayHeader(state: state),
        ),
      ),
    );

    expect(find.textContaining('08/08/2026'), findsOneWidget);
    expect(find.textContaining('1/2 đã hoàn thành'), findsOneWidget);
  });

  testWidgets('progress summary avoids duplicated metric cards', (tester) async {
    final state = _state(
      items: [
        _item(id: 'one', startTime: '08:00', isCompleted: true),
        _item(id: 'two', startTime: '09:00'),
        _item(id: 'three', startTime: '10:00'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleProgressSummary(state: state),
        ),
      ),
    );

    expect(find.text('Tiến độ'), findsOneWidget);
    expect(find.textContaining('1/3 nhiệm vụ đã hoàn thành'), findsOneWidget);
    expect(find.text('Tổng mục'), findsNothing);
    expect(find.text('Còn lại'), findsNothing);
  });

  testWidgets('date selector exposes one clear selected date callback', (
    tester,
  ) async {
    DateTime? selected;
    final dates = [DateTime(2026, 8, 8), DateTime(2026, 8, 9)];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleDateSelector(
            dates: dates,
            selectedDate: dates.first,
            today: dates.first,
            onSelected: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text('9'));
    await tester.pumpAndSettle();

    expect(selected, DateTime(2026, 8, 9));
  });

  testWidgets('open schedule completion action receives tap', (tester) async {
    var tapCount = 0;
    final item = _item(id: 'lunch', startTime: '12:30');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleItemCard(
            item: item,
            categoryIcon: Icons.restaurant_rounded,
            categoryColor: Colors.teal,
            categoryLabel: 'Bữa ăn',
            status: CompletionWindowStatus.open,
            canToggle: true,
            highlighted: false,
            onToggle: () => tapCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.radio_button_unchecked_rounded));
    await tester.pump();

    expect(tapCount, 1);
  });
}

LifestyleScheduleState _state({
  required List<LifestyleScheduleItemEntity> items,
}) {
  return LifestyleScheduleState(
    summary: LifestyleScheduleSummaryEntity(
      userId: 'test-user',
      fullName: 'Người dùng thử',
      items: items,
    ),
    selectedDate: DateTime(2026, 8, 8),
  );
}

LifestyleScheduleItemEntity _item({
  required String id,
  required String startTime,
  bool isCompleted = false,
}) {
  return LifestyleScheduleItemEntity(
    id: id,
    scheduleDate: '2026-08-08',
    startTime: startTime,
    title: 'Nhiệm vụ $id',
    category: LifestyleScheduleCategories.routine,
    sourceType: LifestyleScheduleSourceTypes.aiSchedule,
    isCompleted: isCompleted,
  );
}
