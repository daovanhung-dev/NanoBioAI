import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart';
import 'package:nano_app/app_versions/v1/features/personal_goals/presentation/pages/personal_goals_page.dart';
import 'package:nano_app/core/theme/app_theme.dart';

void main() {
  testWidgets(
    'Nami Care labels local, preview, deterministic and empty states',
    (tester) async {
      await tester.pumpWidget(_testApp(const NamiCarePage()));
      await tester.pumpAndSettle();

      expect(find.text('Lưu trên máy'), findsOneWidget);
      expect(find.text('Xem trước'), findsOneWidget);
      expect(find.text('Bài cố định'), findsNWidgets(2));
      expect(find.text('Chờ dữ liệu'), findsOneWidget);
      expect(find.text('Sẵn sàng'), findsNothing);
      expect(find.textContaining('chuyên gia'), findsOneWidget);
    },
  );

  testWidgets('Personal Goals does not claim an ephemeral choice was saved', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const PersonalGoalsPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Uống đủ nước'));
    await tester.pumpAndSettle();

    expect(find.text('Bạn đang xem trước mục tiêu này'), findsOneWidget);
    expect(find.textContaining('chưa được lưu'), findsWidgets);
    expect(find.textContaining('đã đặt mục tiêu'), findsNothing);
  });
}

Widget _testApp(Widget home) {
  return MaterialApp(theme: AppTheme.lightTheme, home: home);
}
