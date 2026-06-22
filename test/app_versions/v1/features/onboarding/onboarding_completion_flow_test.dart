import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/domain/entities/onboarding_entity.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_completion_provider.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_provider.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/repository_providers.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Onboarding completion flow', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'entrypoints generate initial guest plan without auth early return',
      () {
        for (final path in ['lib/main.dart', 'lib/main_v2.dart']) {
          final source = File(path).readAsStringSync();

          expect(source, contains('generateInitialGuestPlan'));
          expect(
            source,
            isNot(contains('currentSupabaseUserIdOrNull() == null) return')),
          );
        }
      },
    );

    test('sets completed only after initial plan callback succeeds', () async {
      final repository = _FakeOnboardingRepository();
      var callbackCalls = 0;
      final container = ProviderContainer(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(repository),
          onboardingCompletionCallbackProvider.overrideWith((ref) {
            return () async {
              callbackCalls++;
              return const OnboardingCompletionResult.generatedInitialPlan();
            };
          }),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(onboardingProvider.notifier);
      _seedValidState(controller);

      await controller.saveOnboarding();

      expect(repository.saveCalls, 1);
      expect(callbackCalls, 1);
      expect(await AppPrefs.isOnboardingCompleted(), isTrue);
      expect(container.read(onboardingProvider).isSaving, isFalse);
    });

    test('does not set completed when initial plan callback skips', () async {
      final repository = _FakeOnboardingRepository();
      final container = ProviderContainer(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(repository),
          onboardingCompletionCallbackProvider.overrideWith((ref) {
            return () async => const OnboardingCompletionResult.skipped();
          }),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(onboardingProvider.notifier);
      _seedValidState(controller);

      await expectLater(
        controller.saveOnboarding(),
        throwsA(isA<OnboardingInitialPlanException>()),
      );

      expect(repository.saveCalls, 1);
      expect(await AppPrefs.isOnboardingCompleted(), isFalse);
      expect(container.read(onboardingProvider).isSaving, isFalse);
      expect(
        container.read(onboardingProvider).savedLog,
        OnboardingInitialPlanException.userMessage,
      );
    });
  });
}

void _seedValidState(OnboardingController controller) {
  controller.updateFullName('Nguyen Van A');
  controller.updateGender('Nam');
  controller.updateBirthYear('1995');
  controller.updateOccupation('Nhan vien van phong');
  controller.setAgreed(true);
}

class _FakeOnboardingRepository implements OnboardingRepository {
  int saveCalls = 0;
  OnboardingEntity? lastEntity;

  @override
  Future<void> save(OnboardingEntity entity) async {
    saveCalls++;
    lastEntity = entity;
  }
}
