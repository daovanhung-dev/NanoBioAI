import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart';

void main() {
  testWidgets('features hub renders current Nami care tiles', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FeaturesHubPage()));

    expect(find.text('Góc chăm sóc'), findsOneWidget);
    expect(find.text('Lịch trình cá nhân'), findsOneWidget);
    expect(find.text('Trò chuyện với Nami'), findsOneWidget);
  });
}
