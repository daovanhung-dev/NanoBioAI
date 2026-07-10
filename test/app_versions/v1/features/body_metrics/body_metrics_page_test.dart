import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/presentation/pages/body_metrics_page.dart';

void main() {
  testWidgets('shows medical disclaimer copy', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BodyMetricsPage()));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    expect(find.text('Thông tin tham khảo'), findsOneWidget);
    expect(find.textContaining('không thay thế chẩn đoán'), findsOneWidget);
  });
}
