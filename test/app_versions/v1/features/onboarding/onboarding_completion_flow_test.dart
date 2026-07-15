import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/domain/entities/onboarding_entity.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/domain/repositories/onboarding_repository_impl.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/data/datasource/onboarding_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_completion_provider.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_provider.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/repository_providers.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/domain/entities/daily_routine_preferences.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/domain/repositories/daily_routine_preferences_repository.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/providers/daily_routine_preferences_provider.dart';
import 'package:nano_app/core/access/subject_access_context.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Onboarding completion flow', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'single entrypoint generates initial guest plan without auth early return',
      () {
        final source = File('lib/main.dart').readAsStringSync();

        expect(source, contains('generateInitialGuestPlan'));
        expect(
          source,
          isNot(contains('currentSupabaseUserIdOrNull() == null) return')),
        );
      },
    );

    test(
      'persists onboarding locally before any authenticated snapshot drain',
      () {
        final source = File(
          'lib/app_versions/v1/features/onboarding/domain/repositories/'
          'onboarding_repository_impl.dart',
        ).readAsStringSync();

        expect(source, contains('localDatasource.saveOnboarding'));
        expect(source, isNot(contains('saveCompletedOnboarding(')));
        expect(source, contains('currentSupabaseUserIdOrNull'));
        expect(source, isNot(contains('AuthProfileService')));
      },
    );

    test(
      'authenticated save and completion use resolved FamilyPlus subject',
      () async {
        final localDatasource = _CapturingOnboardingLocalDatasource();
        final repository = OnboardingRepositoryImpl(
          localDatasource: localDatasource,
          currentUserId: () => 'actor-1',
          subjectAccessContext: () => const SubjectAccessContext(
            actorId: 'actor-1',
            requestedSubjectId: 'member-1',
            isFamilyPlus: true,
          ),
        );

        await repository.save(_validEntity());
        await repository.markCompleted();

        expect(localDatasource.savedUserIdOverride, 'member-1');
        expect(localDatasource.completedUserId, 'member-1');
      },
    );

    test('sets completed only after initial plan callback succeeds', () async {
      final repository = _FakeOnboardingRepository();
      var callbackCalls = 0;
      final container = ProviderContainer(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(repository),
          dailyRoutinePreferencesRepositoryProvider.overrideWithValue(
            _FakeRoutinePreferencesRepository(),
          ),
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
      expect(repository.markCompletedCalls, 1);
      expect(callbackCalls, 1);
      expect(await AppPrefs.isOnboardingCompleted(), isTrue);
      expect(container.read(onboardingProvider).isSaving, isFalse);
    });

    test('does not set completed when initial plan callback skips', () async {
      final repository = _FakeOnboardingRepository();
      final container = ProviderContainer(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(repository),
          dailyRoutinePreferencesRepositoryProvider.overrideWithValue(
            _FakeRoutinePreferencesRepository(),
          ),
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
      expect(repository.markCompletedCalls, 0);
      expect(await AppPrefs.isOnboardingCompleted(), isFalse);
      expect(container.read(onboardingProvider).isSaving, isFalse);
      expect(
        container.read(onboardingProvider).savedLog,
        OnboardingInitialPlanException.userMessage,
      );
    });

    test(
      'ignores duplicate submit while save is already in progress',
      () async {
        final saveBlocker = Completer<void>();
        final repository = _FakeOnboardingRepository(saveBlocker: saveBlocker);
        var callbackCalls = 0;
        final container = ProviderContainer(
          overrides: [
            onboardingRepositoryProvider.overrideWithValue(repository),
            dailyRoutinePreferencesRepositoryProvider.overrideWithValue(
              _FakeRoutinePreferencesRepository(),
            ),
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

        final firstSave = controller.saveOnboarding();
        final duplicateSave = controller.saveOnboarding();

        expect(repository.saveCalls, 1);
        expect(callbackCalls, 0);

        saveBlocker.complete();
        await Future.wait([firstSave, duplicateSave]);

        expect(repository.saveCalls, 1);
        expect(repository.markCompletedCalls, 1);
        expect(callbackCalls, 1);
        expect(container.read(onboardingProvider).isSaving, isFalse);
      },
    );

    test('does not emit raw onboarding PII in controller logs', () async {
      final repository = _FakeOnboardingRepository();
      final container = ProviderContainer(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(repository),
          dailyRoutinePreferencesRepositoryProvider.overrideWithValue(
            _FakeRoutinePreferencesRepository(),
          ),
          onboardingCompletionCallbackProvider.overrideWith((ref) {
            return () async =>
                const OnboardingCompletionResult.generatedInitialPlan();
          }),
        ],
      );
      addTearDown(container.dispose);

      final logs = await _captureDebugPrint(() async {
        final controller = container.read(onboardingProvider.notifier);
        _seedSensitiveState(controller);

        await controller.saveOnboarding();
      });

      final output = logs.join('\n');
      for (final forbidden in const [
        'Sensitive Person',
        'secret@example.com',
        '0909999999',
        'Private concern',
        'User:',
        'User ID',
        'BMI:',
        '23.',
        'snapshot',
        'StackTrace',
      ]) {
        expect(output, isNot(contains(forbidden)));
      }
    });
  });
}

OnboardingEntity _validEntity() {
  return const OnboardingEntity(
    email: 'member@example.com',
    phone: '0900000000',
    fullName: 'Member One',
    gender: 'female',
    birthYear: 1995,
    occupation: 'office_worker',
    heightCm: 160,
    weightKg: 55,
    goals: ['lose_weight'],
    otherGoal: '',
    conditions: [],
    otherCondition: '',
    habits: [],
    sleepQuality: 'sleep_ok',
    activityLevel: 'light',
    waterPerDay: 'under_1l',
    allergyName: '',
    allergyNote: '',
    treatmentName: '',
    medicationName: '',
    treatmentNote: '',
    concernText: '',
    agreed: true,
  );
}

void _seedValidState(OnboardingController controller) {
  controller.updateFullName('Nguyen Van A');
  controller.updateGender('Nam');
  controller.updateBirthYear('1995');
  controller.updateOccupation('Nhan vien van phong');
  controller.confirmRoutineAndContinue();
  controller.setAgreed(true);
}

void _seedSensitiveState(OnboardingController controller) {
  controller.updateEmail('secret@example.com');
  controller.updatePhone('0909999999');
  controller.updateFullName('Sensitive Person');
  controller.updateGender('Nam');
  controller.updateBirthYear('1995');
  controller.updateOccupation('Nhan vien van phong');
  controller.updateHeight('181');
  controller.updateWeight('77');
  controller.updateConcernText('Private concern');
  controller.toggleGoal('lose_weight');
  controller.toggleCondition('stress');
  controller.toggleHabit('skip_breakfast');
  controller.confirmRoutineAndContinue();
  controller.setAgreed(true);
}

Future<List<String>> _captureDebugPrint(Future<void> Function() action) async {
  final messages = <String>[];
  final previousDebugPrint = debugPrint;

  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) messages.add(message);
  };

  try {
    await action();
  } finally {
    debugPrint = previousDebugPrint;
  }

  return messages;
}

class _FakeOnboardingRepository implements OnboardingRepository {
  final Completer<void>? saveBlocker;
  int saveCalls = 0;
  int markCompletedCalls = 0;
  OnboardingEntity? lastEntity;

  _FakeOnboardingRepository({this.saveBlocker});

  @override
  Future<void> save(OnboardingEntity entity) async {
    saveCalls++;
    lastEntity = entity;
    await saveBlocker?.future;
  }

  @override
  Future<void> markCompleted() async {
    markCompletedCalls++;
  }
}

class _CapturingOnboardingLocalDatasource extends OnboardingLocalDatasource {
  String? savedUserIdOverride;
  String? completedUserId;

  @override
  Future<String> saveOnboarding(
    OnboardingEntity entity, {
    String? userIdOverride,
  }) async {
    savedUserIdOverride = userIdOverride;
    return userIdOverride ?? 'guest-1';
  }

  @override
  Future<void> markOnboardingCompleted(String userId) async {
    completedUserId = userId;
  }
}

class _FakeRoutinePreferencesRepository
    implements DailyRoutinePreferencesRepository {
  int saveCalls = 0;

  @override
  Future<DailyRoutinePreferences?> loadForCurrentUser() async => null;

  @override
  Future<DailyRoutinePreferences?> loadForUser(String userId) async => null;

  @override
  Future<void> saveForCurrentUser(DailyRoutinePreferences preferences) async {
    saveCalls++;
  }

  @override
  Future<void> saveForUser(
    String userId,
    DailyRoutinePreferences preferences,
  ) async {
    saveCalls++;
  }
}
