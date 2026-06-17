import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:nano_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:nano_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OnboardingState', () {
    const validProfile = OnboardingState(
      fullName: 'Nguyen Van A',
      gender: 'Nam',
      birthYear: 1995,
      occupation: 'Nhan vien van phong',
    );

    test('không cho lưu khi người dùng chưa đồng ý điều khoản', () {
      expect(validProfile.canSave, isFalse);
    });

    test('cho lưu khi đủ thông tin và đã đồng ý điều khoản', () {
      expect(validProfile.copyWith(agreed: true).canSave, isTrue);
    });
  });

  test('lưu trạng thái onboarding hoàn tất để dùng cho lần mở sau', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await AppPrefs.isOnboardingCompleted(), isFalse);

    await AppPrefs.setOnboardingCompleted(true);

    expect(await AppPrefs.isOnboardingCompleted(), isTrue);
  });

  testWidgets('onboarding mobile layout has no render exceptions', (
    tester,
  ) async {
    final container = ProviderContainer();
    final view = tester.view;

    view.physicalSize = const Size(390, 844);
    view.devicePixelRatio = 1;

    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OnboardingPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);

    await _tapByText(tester, 'Mình sẵn sàng rồi');

    for (var i = 0; i < 4; i++) {
      await _tapByText(tester, 'Tiếp tục');
    }

    expect(find.text('Bước 6/7'), findsOneWidget);

    container.read(onboardingProvider.notifier).setAgreed(true);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);

    await _tapByText(tester, 'Tiếp tục');

    expect(find.text('Bước 7/7'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _tapByText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).last);
  await tester.pump(const Duration(milliseconds: 500));
  expect(tester.takeException(), isNull);
}
