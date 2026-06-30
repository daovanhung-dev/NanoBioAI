import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/presentation/pages/body_metrics_page.dart';

void main() {
  testWidgets('shows medical disclaimer copy', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: BodyMetricsPage()));
    await tester.scrollUntilVisible(
      find.text('Thong tin tham khao'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('Thong tin tham khao'), findsOneWidget);
    expect(find.textContaining('khong thay the chan doan'), findsOneWidget);
  });
}
