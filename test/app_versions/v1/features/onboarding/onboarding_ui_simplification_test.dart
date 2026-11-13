import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/pages/onboarding_text_scale_page.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/consent_step.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_provider.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('onboarding ambient background is plain', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const NabiAmbientBackground(child: Text('Nội dung')),
      ),
    );

    expect(
      find.descendant(
        of: find.byType(NabiAmbientBackground),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
  });

  testWidgets('text scale shows only the preview and size choices', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const OnboardingTextScalePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cỡ chữ'), findsOneWidget);
    expect(find.text('Xem trước'), findsOneWidget);
    expect(find.text('Chọn cỡ chữ'), findsOneWidget);
    expect(find.text('CÁ NHÂN HÓA'), findsNothing);
    expect(find.text('Nabi'), findsNothing);
    expect(find.byKey(const Key('onboarding_text_scale_nabi')), findsOneWidget);
    expect(
      find.text('Một ngày mới, một bước chăm sóc bản thân.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Image>(find.byKey(const Key('onboarding_text_scale_nabi')))
          .width,
      112,
    );

    await tester.tap(find.text('Lớn'));
    await tester.pumpAndSettle();

    final preview = tester.widget<Text>(
      find.text('Một ngày mới, một bước chăm sóc bản thân.'),
    );
    expect(preview.style?.fontSize, 18);

    tester.view.physicalSize = const Size(320, 640);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Image>(find.byKey(const Key('onboarding_text_scale_nabi')))
          .width,
      88,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('routine asks each core time separately for both profiles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = _container(const OnboardingState(currentStep: 6));
    addTearDown(container.dispose);
    await _pumpOnboarding(tester, container);

    const questions = [
      'Bạn thức dậy vào lúc mấy giờ?',
      'Bạn ăn sáng từ lúc mấy giờ?',
      'Bạn ăn bữa phụ sáng lúc mấy giờ?',
      'Bạn ăn trưa từ lúc mấy giờ?',
      'Bạn ăn bữa phụ chiều lúc mấy giờ?',
      'Bạn ăn tối từ lúc mấy giờ?',
      'Bạn thường đi ngủ lúc mấy giờ?',
    ];

    for (var index = 0; index < questions.length; index++) {
      expect(find.text(questions[index]), findsOneWidget);
      expect(find.text('NGÀY THƯỜNG'), findsOneWidget);
      if (index < questions.length - 1) {
        await tester.tap(find.byKey(const Key('daily_routine_next')));
        await tester.pumpAndSettle();
      }
    }

    await tester.tap(find.byKey(const Key('daily_routine_next')));
    await tester.pumpAndSettle();
    expect(find.text(questions.first), findsOneWidget);
    expect(find.text('CUỐI TUẦN'), findsOneWidget);
    expect(find.text('07:30'), findsOneWidget);

    for (var index = 0; index < questions.length; index++) {
      expect(find.text(questions[index]), findsOneWidget);
      expect(find.text('CUỐI TUẦN'), findsOneWidget);
      await tester.tap(find.byKey(const Key('daily_routine_next')));
      await tester.pumpAndSettle();
    }

    expect(find.text('Bạn muốn thêm giờ nào không?'), findsOneWidget);
    expect(find.text('Thêm giờ tùy chọn'), findsOneWidget);
    expect(find.text('Bữa sáng'), findsNothing);

    await tester.tap(find.byKey(const Key('daily_routine_optional_editor')));
    await tester.pumpAndSettle();
    expect(find.text('Khung ngủ trưa'), findsWidgets);
    expect(find.text('Khung tập 1'), findsWidgets);
    expect(find.text('Bữa sáng'), findsNothing);

    await tester.tap(find.byKey(const Key('daily_routine_confirm')));
    await tester.pumpAndSettle();
    expect(container.read(onboardingProvider).currentStep, 7);
    expect(container.read(onboardingProvider).routineConfirmed, isTrue);
  });

  testWidgets('system back moves to the previous routine question first', (
    tester,
  ) async {
    final container = _container(
      const OnboardingState(currentStep: 6, routineQuestionIndex: 1),
    );
    addTearDown(container.dispose);
    await _pumpOnboarding(tester, container);

    expect(find.text('Bạn ăn sáng từ lúc mấy giờ?'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(container.read(onboardingProvider).currentStep, 6);
    expect(container.read(onboardingProvider).routineQuestionIndex, 0);
    expect(find.text('Bạn thức dậy vào lúc mấy giờ?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding_back')));
    await tester.pumpAndSettle();
    expect(container.read(onboardingProvider).currentStep, 5);
  });

  testWidgets('consent keeps its summary short and details expandable', (
    tester,
  ) async {
    final container = _container(const OnboardingState(currentStep: 7));
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: ConsentStep()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Hồ sơ lưu trong ứng dụng. Khi dùng AI qua máy chủ, dữ liệu cần thiết được gửi tới NanoBio.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Nabi gợi ý lối sống, không thay thế chẩn đoán y tế.'),
      findsOneWidget,
    );
    expect(find.textContaining('Whisper').hitTestable(), findsNothing);

    await tester.tap(find.byKey(const Key('onboarding_consent_details')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Whisper').hitTestable(), findsOneWidget);

    final consentToggle = find.byKey(const Key('onboarding_consent_toggle'));
    await tester.ensureVisible(consentToggle);
    await tester.tap(consentToggle);
    await tester.pumpAndSettle();
    expect(container.read(onboardingProvider).agreed, isTrue);
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(container.read(onboardingProvider).currentStep, 8);
  });
}

ProviderContainer _container(OnboardingState initialState) {
  return ProviderContainer(
    overrides: [
      onboardingProvider.overrideWith(
        () => _TestOnboardingController(initialState),
      ),
    ],
  );
}

Future<void> _pumpOnboarding(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const OnboardingPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _TestOnboardingController extends OnboardingController {
  _TestOnboardingController(this.initialState);

  final OnboardingState initialState;

  @override
  OnboardingState build() => initialState;
}
