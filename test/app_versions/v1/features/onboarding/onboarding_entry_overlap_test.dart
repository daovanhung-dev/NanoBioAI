import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart';

void main() {
  testWidgets('decorative moon never overlaps the personalization tag', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: const OnboardingEntryPage(),
        ),
      ),
    );
    await tester.pump();

    final moon = find.byKey(const Key('onboarding_entry_moon_orb'));
    final personalization = find.text('Cá nhân hóa');

    expect(moon, findsOneWidget);
    expect(personalization, findsOneWidget);
    expect(
      tester.getRect(moon).overlaps(tester.getRect(personalization)),
      isFalse,
    );
  });
}
