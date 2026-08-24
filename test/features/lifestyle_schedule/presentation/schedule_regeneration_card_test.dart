import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/presentation/widgets/schedule_regeneration_card.dart';

void main() {
  Widget host(Widget child) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }

  testWidgets('disables generation when two or more days remain', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      host(
        ScheduleRegenerationCard(
          remainingDays: 2,
          isLoading: false,
          hasError: false,
          isGenerating: false,
          onGenerate: () => taps++,
        ),
      ),
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('schedule-regeneration-button')),
    );
    expect(button.onPressed, isNull);
    expect(find.textContaining('Lịch hiện tại còn 2 ngày'), findsOneWidget);
    expect(find.textContaining('còn dưới 2 ngày'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('schedule-regeneration-button')),
    );
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('enables generation when exactly one day remains', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      host(
        ScheduleRegenerationCard(
          remainingDays: 1,
          isLoading: false,
          hasError: false,
          isGenerating: false,
          onGenerate: () => taps++,
        ),
      ),
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('schedule-regeneration-button')),
    );
    expect(button.onPressed, isNotNull);
    expect(find.text('Tạo lịch trình mới'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('schedule-regeneration-button')),
    );
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('enables generation when no day remains', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      host(
        ScheduleRegenerationCard(
          remainingDays: 0,
          isLoading: false,
          hasError: false,
          isGenerating: false,
          onGenerate: () => taps++,
        ),
      ),
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('schedule-regeneration-button')),
    );
    expect(button.onPressed, isNotNull);
    expect(find.text('Tạo lịch trình mới'), findsOneWidget);
    expect(find.textContaining('đã hết ngày'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('schedule-regeneration-button')),
    );
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('locks the button while Nabi is generating', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      host(
        ScheduleRegenerationCard(
          remainingDays: 1,
          isLoading: false,
          hasError: false,
          isGenerating: true,
          onGenerate: () => taps++,
        ),
      ),
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('schedule-regeneration-button')),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Nabi đang tạo lịch...'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('schedule-regeneration-button')),
    );
    await tester.pump();
    expect(taps, 0);
  });
}
