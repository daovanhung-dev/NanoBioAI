import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_provider.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OnboardingState', () {
    const validProfile = OnboardingState(
      fullName: 'Nguyen Van A',
      gender: 'Nam',
      birthYear: 1995,
      occupation: 'Nhan vien van phong',
      routineConfirmed: true,
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

  test(
    'onboarding AI dev check provider does not call AI when disabled',
    () async {
      var calls = 0;
      final service = AIService(
        modelNames: const ['fake-model'],
        textGenerator: ({required modelName, required prompt}) async {
          calls++;
          return '[{"status_code":"ai_connection_ok"}]';
        },
      );
      final container = ProviderContainer(
        overrides: [
          onboardingAiDevCheckEnabledProvider.overrideWithValue(false),
          aiServiceProvider.overrideWithValue(service),
        ],
      );

      addTearDown(container.dispose);

      final result = await container.read(onboardingAiDevCheckProvider.future);

      expect(result, isNull);
      expect(calls, 0);
    },
  );

  testWidgets('AI dev banner is hidden when env flag is disabled', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [onboardingAiDevCheckEnabledProvider.overrideWithValue(false)],
    );
    addTearDown(container.dispose);

    await _pumpOnboardingPage(tester, container);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(_aiDevCheckBannerKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI dev success stays out of the user-facing onboarding UI', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        onboardingAiDevCheckEnabledProvider.overrideWithValue(true),
        onboardingAiDevCheckProvider.overrideWith(
          (ref) async =>
              const AIConnectionCheckResult.success(modelName: 'fake-model'),
        ),
      ],
    );
    addTearDown(container.dispose);

    await _pumpOnboardingPage(tester, container);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(_aiDevCheckBannerKey), findsNothing);
    expect(find.text('Trợ lý đã sẵn sàng: fake-model.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI dev failure stays private and does not block next step', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        onboardingAiDevCheckEnabledProvider.overrideWithValue(true),
        onboardingAiDevCheckProvider.overrideWith(
          (ref) async => const AIConnectionCheckResult.failure(
            message: 'AI test failed',
            modelName: 'fake-model',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await _pumpOnboardingPage(tester, container);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(_aiDevCheckBannerKey), findsNothing);
    expect(find.text('AI test failed'), findsNothing);

    await _tapPrimaryOnboardingButton(tester);
    await tester.pump(const Duration(seconds: 1));

    expect(container.read(onboardingProvider).currentStep, 1);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
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

    for (var step = 0; step < 9; step++) {
      container.read(onboardingProvider.notifier).goToStep(step);
      await tester.pump(const Duration(milliseconds: 500));

      expect(container.read(onboardingProvider).currentStep, step);
      expect(find.text('Bước ${step + 1}/9'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    container.read(onboardingProvider.notifier).goToStep(6);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Bước 7/9'), findsOneWidget);
    expect(find.text('Một ngày của bạn'), findsNothing);
    expect(find.byKey(const Key('onboarding_back')), findsAtLeastNWidgets(1));
    expect(find.text('Xác nhận khung giờ'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('onboarding next and back retain the selected profile data', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _pumpOnboardingPage(tester, container);
    await _tapOnboardingAction(tester, 'Bắt đầu');
    expect(container.read(onboardingProvider).currentStep, 1);

    final controller = container.read(onboardingProvider.notifier);
    controller.updateFullName('Nguyen Van A');
    controller.updateGender('Nam');
    controller.updateBirthYear('1995');
    controller.updateOccupation('office');
    await tester.pump();
    await _tapOnboardingAction(tester, 'Tiếp tục');
    expect(container.read(onboardingProvider).currentStep, 2);

    await tester.ensureVisible(find.text('Ngủ ngon hơn'));
    await tester.tap(find.text('Ngủ ngon hơn'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(onboardingProvider).goals, contains('sleep_better'));

    final backButtons = find.byKey(const Key('onboarding_back'));
    await tester.tap(backButtons.last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(container.read(onboardingProvider).currentStep, 1);
    expect(container.read(onboardingProvider).fullName, 'Nguyen Van A');
    expect(
      tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .any((field) => field.controller?.text == 'Nguyen Van A'),
      isTrue,
    );

    await _tapOnboardingAction(tester, 'Tiếp tục');
    expect(container.read(onboardingProvider).currentStep, 2);
    expect(container.read(onboardingProvider).goals, contains('sleep_better'));
    expect(find.text('1 mục tiêu đã chọn'), findsOneWidget);

    await _tapOnboardingAction(tester, 'Tiếp tục');
    await _tapOnboardingAction(tester, 'Tiếp tục');
    await _tapOnboardingAction(tester, 'Tiếp tục');
    await _tapOnboardingAction(tester, 'Tiếp tục');
    expect(container.read(onboardingProvider).currentStep, 6);

    await _tapOnboardingAction(tester, 'Xác nhận khung giờ');
    expect(container.read(onboardingProvider).currentStep, 7);
    controller.setAgreed(true);
    await tester.pump();
    await _tapOnboardingAction(tester, 'Tiếp tục');
    expect(container.read(onboardingProvider).currentStep, 8);
    expect(find.textContaining('Ngủ ngon hơn'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('onboarding fits compact screens with larger text and keyboard', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _pumpOnboardingPage(
      tester,
      container,
      size: const Size(320, 640),
      textScale: 1.3,
    );
    await tester.pump(const Duration(milliseconds: 500));

    for (var step = 0; step < 9; step++) {
      container.read(onboardingProvider.notifier).goToStep(step);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull, reason: 'step ${step + 1}/9');
    }

    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    container.read(onboardingProvider.notifier).goToStep(1);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(find.text('Họ và tên *'));
    await tester.tap(find.text('Họ và tên *'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

const _aiDevCheckBannerKey = Key('onboarding_ai_dev_check_banner');

Future<void> _pumpOnboardingPage(
  WidgetTester tester,
  ProviderContainer container, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  final view = tester.view;

  view.physicalSize = size;
  view.devicePixelRatio = 1;

  addTearDown(() {
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
    view.resetViewInsets();
    tester.binding.focusManager.primaryFocus?.unfocus();
  });

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: const OnboardingPage(),
          ),
        ),
      ),
    ),
  );
}

Future<void> _tapPrimaryOnboardingButton(WidgetTester tester) async {
  final button = find
      .byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onTap != null,
      )
      .last;
  await tester.tap(button);
  await tester.pump(const Duration(milliseconds: 500));
  expect(tester.takeException(), isNull);
}

Future<void> _tapOnboardingAction(WidgetTester tester, String label) async {
  final action = find.text(label).last;
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pump(const Duration(milliseconds: 500));
  expect(tester.takeException(), isNull, reason: label);
}
