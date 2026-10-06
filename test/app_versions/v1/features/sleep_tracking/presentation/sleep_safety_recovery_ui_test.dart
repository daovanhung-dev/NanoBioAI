import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/services/sleep_safety_state_machine.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/presentation/widgets/sleep_safety_alert_overlay.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/presentation/widgets/sleep_safety_status_card.dart';

void main() {
  testWidgets('missing call-eligible contact opens contacts instead of retry', (
    tester,
  ) async {
    var openedContacts = false;
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SleepSafetyAlertOverlay(
            startedAt: DateTime.now(),
            onOk: () {},
            onNeedHelp: () {},
            dispatching: false,
            dispatchFailed: true,
            dispatchError:
                'Chưa có liên hệ đủ điều kiện nhận cuộc gọi cảnh báo.',
            requiresContactSetup: true,
            onRetry: () => retryCount += 1,
            onManageContacts: () => openedContacts = true,
          ),
        ),
      ),
    );

    expect(find.text('Mở danh bạ'), findsOneWidget);
    expect(find.text('Thử gửi lại'), findsNothing);
    await tester.tap(find.text('Mở danh bạ'));
    expect(openedContacts, isTrue);
    expect(retryCount, 0);
  });

  testWidgets('phone handoff failure keeps the retry and response actions', (
    tester,
  ) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SleepSafetyAlertOverlay(
            startedAt: DateTime.now(),
            onOk: () {},
            onNeedHelp: () {},
            dispatching: false,
            dispatchFailed: true,
            dispatchError: 'Nhà cung cấp chưa phản hồi.',
            onRetry: () => retryCount += 1,
          ),
        ),
      ),
    );

    expect(find.text('Thử gọi lại'), findsOneWidget);
    expect(find.text('Mở danh bạ'), findsNothing);
    expect(find.text('Tôi ổn'), findsOneWidget);
    expect(find.text('Tôi cần hỗ trợ'), findsOneWidget);
    await tester.tap(find.text('Thử gọi lại'));
    expect(retryCount, 1);
  });

  testWidgets('alert does not show a system-config pause message', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SleepSafetyAlertOverlay(
            startedAt: DateTime.now(),
            onOk: () {},
            onNeedHelp: () {},
            dispatching: false,
          ),
        ),
      ),
    );

    expect(find.textContaining('tạm dừng theo cài đặt hệ thống'), findsNothing);
    expect(find.textContaining('Gọi ngay'), findsNothing);
    expect(find.text('Tôi cần hỗ trợ'), findsOneWidget);
  });

  testWidgets('manual help failure ends loading and offers recovery actions', (
    tester,
  ) async {
    var retried = false;
    var openedContacts = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SleepSafetyAlertOverlay(
            startedAt: DateTime.now(),
            onOk: () {},
            onNeedHelp: () {},
            dispatching: false,
            manualHelpFailed: true,
            manualHelpError: 'Chưa thể mở cuộc gọi.',
            onRetryHelp: () => retried = true,
            onManageContacts: () => openedContacts = true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Thử gọi lại'), findsOneWidget);
    expect(find.text('Mở danh bạ'), findsOneWidget);
    await tester.tap(find.text('Thử gọi lại'));
    await tester.tap(find.text('Mở danh bạ'));
    expect(retried, isTrue);
    expect(openedContacts, isTrue);
  });

  testWidgets('manual help shows loading only while the call is starting', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SleepSafetyAlertOverlay(
            startedAt: DateTime.now(),
            onOk: () {},
            onNeedHelp: () {},
            dispatching: false,
            manualHelpPending: true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Nabi đang chuẩn bị cuộc gọi…'), findsOneWidget);
    expect(find.text('Tôi cần hỗ trợ'), findsNothing);
  });

  testWidgets(
    'no verified contacts shows a warning without blocking local monitoring',
    (tester) async {
      var started = false;
      var openedContacts = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SleepSafetyStatusCard(
              phase: SleepSafetyPhase.idle,
              sensitivity: 'Cân bằng',
              contactsLoaded: true,
              verifiedContacts: 0,
              callReadyContacts: 0,
              busy: false,
              onStart: () => started = true,
              onStop: () {},
              onManageContacts: () => openedContacts = true,
            ),
          ),
        ),
      );

      expect(
        find.textContaining('bật quyền nhận cuộc gọi thoại'),
        findsOneWidget,
      );
      expect(find.textContaining('đang tạm dừng'), findsNothing);
      expect(find.text('Bắt đầu giám sát đêm nay'), findsOneWidget);

      await tester.tap(find.text('Mở danh bạ'));
      expect(openedContacts, isTrue);
      await tester.tap(find.text('Bắt đầu giám sát đêm nay'));
      expect(started, isTrue);
    },
  );
}
