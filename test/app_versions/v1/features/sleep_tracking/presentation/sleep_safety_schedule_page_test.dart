import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/sleep_safety_preference.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/services/sleep_safety_state_machine.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_safety_schedule_page.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/providers/sleep_safety_controller.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/providers/sleep_safety_providers.dart';
import 'package:nano_app/core/theme/theme.dart';

void main() {
  testWidgets('schedule is usable on a narrow screen and saves the selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = _ScheduleTestController();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sleepSafetyControllerProvider.overrideWith(() => controller),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SleepSafetySchedulePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Chọn nhịp giám sát phù hợp với giờ nghỉ của bạn.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Ngày áp dụng'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Thứ 2'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Thứ 2'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Lưu lịch'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Lưu lịch'));
    await tester.pumpAndSettle();

    expect(controller.savedPreference, isNotNull);
    expect(controller.savedPreference!.selectedWeekdays, {2, 3, 4, 5, 6, 7});
    expect(controller.savedPreference!.scheduleStartMinutes, 1350);
    expect(controller.savedPreference!.scheduleEndMinutes, 390);
    expect(tester.takeException(), isNull);
  });
}

class _ScheduleTestController extends SleepSafetyController {
  SleepSafetyPreference? savedPreference;

  @override
  SleepSafetyViewState build() => SleepSafetyViewState(
    machine: const SleepSafetyMachineState.idle(),
    contacts: const [],
    history: const [],
    preference: SleepSafetyPreference.defaults('user-test'),
  );

  @override
  Future<void> savePreference(SleepSafetyPreference preference) async {
    savedPreference = preference;
  }
}
