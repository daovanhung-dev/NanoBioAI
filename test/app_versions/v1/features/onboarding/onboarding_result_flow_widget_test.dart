import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/domain/entities/daily_routine_preferences.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/domain/repositories/daily_routine_preferences_repository.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/providers/daily_routine_preferences_provider.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/domain/entities/onboarding_entity.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/pages/onboarding_result_page.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/review_step.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_completion_provider.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_provider.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/repository_providers.dart';
import 'package:nano_app/app_versions/v1/services/ai/generated_plan_service.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('successful save shows the completion screen before Menu', (
    tester,
  ) async {
    final repository = _FakeOnboardingRepository();
    final container = _container(repository: repository);
    final router = _router(initialLocation: '/review');
    addTearDown(container.dispose);
    addTearDown(router.dispose);

    _seedReviewState(container.read(onboardingProvider.notifier));
    await _pump(tester, container, router);

    await tester.ensureVisible(
      find.byKey(const Key('onboarding_review_create_plan')),
    );
    await tester.tap(find.byKey(const Key('onboarding_review_create_plan')));
    await _pumpUntil(
      tester,
      find.text('Bạn đã sẵn sàng đồng hành cùng Nabi chưa?'),
    );

    expect(repository.saveCalls, 1);
    expect(repository.markCompletedCalls, 1);
    expect(await AppPrefs.isOnboardingCompleted(), isTrue);
    expect(
      find.text(container.read(onboardingProvider).savedLog!),
      findsOneWidget,
    );
    expect(
      find.text(
        'Hồ sơ và lịch gợi ý cơ bản đã sẵn sàng. Bạn có thể tạo lịch cá nhân hơn sau.',
      ),
      findsOneWidget,
    );
    expect(find.text('Vào ứng dụng'), findsOneWidget);
    expect(find.text('Menu'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Vào ứng dụng'));
    await _pumpUntil(tester, find.text('Menu'));
  });

  testWidgets('failed save keeps the review screen and does not celebrate', (
    tester,
  ) async {
    final repository = _FakeOnboardingRepository();
    final container = _container(
      repository: repository,
      onComplete: ({onProgress}) async =>
          throw const OnboardingInitialPlanException('Bạn thử lại nhé.'),
    );
    final router = _router(initialLocation: '/review');
    addTearDown(container.dispose);
    addTearDown(router.dispose);

    _seedReviewState(container.read(onboardingProvider.notifier));
    await _pump(tester, container, router);

    await tester.ensureVisible(
      find.byKey(const Key('onboarding_review_create_plan')),
    );
    await tester.tap(find.byKey(const Key('onboarding_review_create_plan')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.text('Bạn đã sẵn sàng đồng hành cùng Nabi chưa?'),
      findsNothing,
    );
    expect(
      container.read(onboardingProvider).savedLog,
      OnboardingInitialPlanException.userMessage,
    );
    expect(router.routeInformationProvider.value.uri.path, '/review');
    expect(repository.markCompletedCalls, 0);
    expect(await AppPrefs.isOnboardingCompleted(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('awaiting meal approval stays outside the completion screen', (
    tester,
  ) async {
    final proposal = GeneratedCustomMealProposal(
      proposalId: 'proposal-1',
      stagingKey: 'meal-1',
      day: 1,
      mealType: 'lunch',
      name: 'Món chờ duyệt',
      description: 'Mô tả món ăn.',
      ingredients: const ['Rau củ'],
      servingSize: '1 phần',
      cookingSteps: const ['Nấu chín'],
    );
    final repository = _FakeOnboardingRepository();
    final container = _container(
      repository: repository,
      onComplete: ({onProgress}) async {
        onProgress?.call(
          GeneratedPlanProgress.empty(
            totalDays: 7,
            requestId: 'request-1',
            pendingMealProposal: proposal,
          ),
        );
        return OnboardingCompletionResult.awaitingCustomMeal(
          requestId: 'request-1',
          proposal: proposal,
        );
      },
    );
    final router = _router(initialLocation: '/review');
    addTearDown(container.dispose);
    addTearDown(router.dispose);

    _seedReviewState(container.read(onboardingProvider.notifier));
    await _pump(tester, container, router);

    await tester.ensureVisible(
      find.byKey(const Key('onboarding_review_create_plan')),
    );
    await tester.tap(find.byKey(const Key('onboarding_review_create_plan')));
    await _pumpUntil(tester, find.text('Món chờ bạn duyệt · Ngày thứ 1'));

    expect(
      find.text('Bạn đã sẵn sàng đồng hành cùng Nabi chưa?'),
      findsNothing,
    );
    expect(find.text('Duyệt món'), findsOneWidget);
    expect(repository.markCompletedCalls, 0);
    expect(await AppPrefs.isOnboardingCompleted(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('result route without completion data redirects to Menu', (
    tester,
  ) async {
    final router = _router(initialLocation: V1RoutePaths.onboardingResult);
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await _pumpUntil(
      tester,
      find.text('Bạn đã sẵn sàng đồng hành cùng Nabi chưa?'),
    );

    expect(find.text('Menu'), findsOneWidget);
    expect(
      find.text('Bạn đã sẵn sàng đồng hành cùng Nabi chưa?'),
      findsNothing,
    );
  });

  testWidgets('system back from the completion screen opens Menu', (
    tester,
  ) async {
    final router = _router(
      initialLocation: V1RoutePaths.onboardingResult,
      initialExtra: const OnboardingResultRouteData(message: 'Đã lưu hồ sơ.'),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await _pumpUntil(
      tester,
      find.text('Bạn đã sẵn sàng đồng hành cùng Nabi chưa?'),
    );
    expect(
      find.text('Bạn đã sẵn sàng đồng hành cùng Nabi chưa?'),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await _pumpUntil(tester, find.text('Menu'));

    expect(find.text('Menu'), findsOneWidget);
  });
}

ProviderContainer _container({
  required _FakeOnboardingRepository repository,
  OnboardingCompletionCallback? onComplete,
}) {
  return ProviderContainer(
    overrides: [
      onboardingRepositoryProvider.overrideWithValue(repository),
      dailyRoutinePreferencesRepositoryProvider.overrideWithValue(
        _FakeRoutinePreferencesRepository(),
      ),
      if (onComplete != null)
        onboardingCompletionCallbackProvider.overrideWith((ref) => onComplete)
      else
        onboardingCompletionCallbackProvider.overrideWith(
          (ref) =>
              ({onProgress}) async =>
                  const OnboardingCompletionResult.generatedInitialPlan(),
        ),
    ],
  );
}

GoRouter _router({required String initialLocation, Object? initialExtra}) =>
    GoRouter(
      initialLocation: initialLocation,
      initialExtra: initialExtra,
      routes: [
        GoRoute(
          path: '/review',
          builder: (context, state) => const Scaffold(body: ReviewStep()),
        ),
        GoRoute(
          path: V1RoutePaths.onboardingResult,
          redirect: (context, state) => state.extra is OnboardingResultRouteData
              ? null
              : V1RoutePaths.menu,
          builder: (context, state) {
            final routeData = state.extra;
            return OnboardingResultPage(
              message: routeData is OnboardingResultRouteData
                  ? routeData.message
                  : '',
            );
          },
        ),
        GoRoute(
          path: V1RoutePaths.menu,
          builder: (context, state) => const Scaffold(body: Text('Menu')),
        ),
      ],
    );

void _seedReviewState(OnboardingController controller) {
  controller.updateFullName('Nguyen Van A');
  controller.updateGender('Nam');
  controller.updateBirthYear('1995');
  controller.updateOccupation('Nhan vien van phong');
  controller.confirmRoutineAndContinue();
  controller.setAgreed(true);
  controller.goToStep(8);
}

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer container,
  GoRouter router,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 20 && finder.evaluate().isEmpty; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _FakeOnboardingRepository implements OnboardingRepository {
  int saveCalls = 0;
  int markCompletedCalls = 0;

  @override
  Future<void> save(OnboardingEntity entity) async {
    saveCalls++;
  }

  @override
  Future<void> markCompleted() async {
    markCompletedCalls++;
  }
}

class _FakeRoutinePreferencesRepository
    implements DailyRoutinePreferencesRepository {
  @override
  Future<DailyRoutinePreferences?> loadForCurrentUser() async => null;

  @override
  Future<DailyRoutinePreferences?> loadForUser(String userId) async => null;

  @override
  Future<void> saveForCurrentUser(DailyRoutinePreferences preferences) async {}

  @override
  Future<void> saveForUser(
    String userId,
    DailyRoutinePreferences preferences,
  ) async {}
}
