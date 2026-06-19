import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart';

void main() {
  testWidgets('placeholder feature shows development snackbar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FeaturesHubPage()));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -360));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI Coach'));
    await tester.pump();

    expect(find.text('Tính năng đang phát triển'), findsOneWidget);
  });
}
