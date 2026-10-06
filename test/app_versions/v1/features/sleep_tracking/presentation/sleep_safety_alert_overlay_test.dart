import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/presentation/widgets/sleep_safety_alert_overlay.dart';

void main() {
  testWidgets('alert countdown starts at 15 seconds', (tester) async {
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

    expect(find.text('15 giây'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
