import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/pages/onboarding_text_scale_page.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/consent_step.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_provider.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/domain/entities/daily_routine_preferences.dart';
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

  testWidgets('routine asks every stored field for both profiles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = _container(const OnboardingState(currentStep: 6));
    addTearDown(container.dispose);
    await _pumpOnboarding(tester, container);

    const coreQuestions = [
      'Bạn thức dậy vào lúc mấy giờ?',
      'Bạn ăn sáng từ lúc mấy giờ?',
      'Bạn ăn bữa phụ sáng lúc mấy giờ?',
      'Bạn ăn trưa từ lúc mấy giờ?',
      'Bạn ăn bữa phụ chiều lúc mấy giờ?',
      'Bạn ăn tối từ lúc mấy giờ?',
      'Bạn thường đi ngủ lúc mấy giờ?',
    ];

    for (final profile in ['NGÀY THƯỜNG', 'CUỐI TUẦN']) {
      for (final question in coreQuestions) {
        expect(find.text(question), findsOneWidget);
        expect(find.text(profile), findsOneWidget);
        expect(find.byKey(const Key('daily_routine_nabi')), findsOneWidget);
        await tester.tap(find.byKey(const Key('daily_routine_next')));
        await tester.pumpAndSettle();
      }

      expect(find.text('Bạn có ngủ trưa không?'), findsOneWidget);
      await tester.tap(find.text('Không'));
      await tester.pumpAndSettle();
      final preferences = container.read(onboardingProvider).routinePreferences;
      expect(
        profile == 'NGÀY THƯỜNG'
            ? preferences.weekday.napEnabled
            : preferences.weekend.napEnabled,
        isFalse,
      );
      await tester.tap(find.byKey(const Key('daily_routine_next')));
      await tester.pumpAndSettle();

      expect(
        find.text('Bạn thường ngủ trưa từ mấy giờ đến mấy giờ?'),
        findsNothing,
      );
      expect(
        find.text('Lần tập đầu tiên trong ngày của bạn là khi nào?'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('daily_routine_range_start')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('daily_routine_range_end')), findsOneWidget);
      await tester.tap(find.byKey(const Key('daily_routine_next')));
      await tester.pumpAndSettle();

      expect(
        find.text('Lần tập thứ hai trong ngày của bạn là khi nào?'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('daily_routine_next')));
      await tester.pumpAndSettle();
      expect(
        find.text('Bạn có khoảng thời gian bận học hoặc làm việc không?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Không'));
      await tester.pumpAndSettle();
      if (profile == 'NGÀY THƯỜNG') {
        await tester.tap(find.byKey(const Key('daily_routine_next')));
        await tester.pumpAndSettle();
      }
    }

    expect(find.byKey(const Key('daily_routine_confirm')), findsOneWidget);
    expect(find.text('Bạn thường bận từ mấy giờ đến mấy giờ?'), findsNothing);
    await tester.tap(find.byKey(const Key('daily_routine_confirm')));
    await tester.pumpAndSettle();
    final completed = container.read(onboardingProvider);
    expect(completed.currentStep, 7);
    expect(completed.routineConfirmed, isTrue);
    expect(completed.routinePreferences.validate(), isEmpty);
    expect(completed.routinePreferences.weekday.napEnabled, isFalse);
    expect(completed.routinePreferences.weekend.napEnabled, isFalse);
    expect(completed.routinePreferences.weekday.busyRange, isNull);
    expect(completed.routinePreferences.weekend.busyRange, isNull);
  });

  testWidgets('routine asks nap and busy intervals when enabled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final defaults = DailyRoutinePreferences.defaultValue;
    final preferences = defaults.copyWith(
      weekday: defaults.weekday.copyWith(clearBusyRange: true),
    );
    final container = _container(
      OnboardingState(
        currentStep: 6,
        routineQuestionIndex: 7,
        routinePreferences: preferences,
      ),
    );
    addTearDown(container.dispose);
    await _pumpOnboarding(tester, container);

    expect(find.text('Bạn có ngủ trưa không?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('daily_routine_next')));
    await tester.pumpAndSettle();
    expect(
      find.text('Bạn thường ngủ trưa từ mấy giờ đến mấy giờ?'),
      findsOneWidget,
    );
    expect(find.text('12:45'), findsOneWidget);
    expect(find.text('13:15'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding_back')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Không'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('daily_routine_next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('daily_routine_next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('daily_routine_next')));
    await tester.pumpAndSettle();

    expect(
      find.text('Bạn có khoảng thời gian bận học hoặc làm việc không?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Có'));
    await tester.pumpAndSettle();
    expect(
      container.read(onboardingProvider).routinePreferences.weekday.busyRange,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('daily_routine_next')));
    await tester.pumpAndSettle();
    expect(find.text('Bạn thường bận từ mấy giờ đến mấy giờ?'), findsOneWidget);
    expect(find.byKey(const Key('daily_routine_nabi')), findsOneWidget);
    expect(find.byKey(const Key('daily_routine_range_start')), findsOneWidget);
    expect(find.byKey(const Key('daily_routine_range_end')), findsOneWidget);
  });

  testWidgets(
    'routine illustration and interval controls fit compact screens',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = _container(
        const OnboardingState(currentStep: 6, routineQuestionIndex: 8),
      );
      addTearDown(container.dispose);
      await _pumpOnboarding(tester, container);

      expect(
        find.text('Bạn thường ngủ trưa từ mấy giờ đến mấy giờ?'),
        findsOneWidget,
      );
      final nabi = tester.widget<Image>(
        find.byKey(const Key('daily_routine_nabi')),
      );
      expect(nabi.width, 72);
      expect(nabi.height, 72);
      expect(
        find.byKey(const Key('daily_routine_range_start')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('daily_routine_range_end')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

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
