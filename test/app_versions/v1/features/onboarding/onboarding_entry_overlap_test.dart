import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/pages/onboarding_entry_page.dart';

void main() {
  testWidgets(
    'entry hero stays clear of actions at large text on a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: const OnboardingEntryPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final hero = find.byKey(const Key('onboarding_entry_hero'));
      final guestAction = find.byKey(const Key('onboarding_entry_guest_cta'));

      expect(hero, findsOneWidget);
      expect(guestAction, findsOneWidget);
      expect(
        tester.getRect(hero).overlaps(tester.getRect(guestAction)),
        isFalse,
      );
    },
  );
}
