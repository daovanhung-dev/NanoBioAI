import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/application/fitness_training_service.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/data/datasources/fitness_training_catalog_asset_datasource.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/entities/fitness_training_catalog.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/entities/fitness_schedule_conflict.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/entities/fitness_training_program.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/repositories/fitness_training_repository.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/services/fitness_program_validator.dart';
import 'package:nano_app/app_versions/v1/services/ai/gemini_rest_client.dart';
import 'package:nano_app/app_versions/v1/services/ai/personal_schedule_quota_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FitnessTrainingCatalog catalog;
  setUpAll(() async {
    catalog = await const FitnessTrainingCatalogAssetDatasource().load();
  });

  test('same request ID reuses saved plan and charges M02 once', () async {
    final repository = _MemoryRepository();
    final quota = _QuotaGateway();
    var aiCalls = 0;
    final service = FitnessTrainingService(
      repository: repository,
      quotaGateway: quota,
      currentUserId: () => 'member-1',
      now: () => DateTime(2026, 10, 5, 8),
      idGenerator: () => 'program-1',
      validator: _AcceptingValidator(),
      aiClientFactory: (_) => _FakeAiClient(() {
        aiCalls++;
        return '{"days":[]}';
      }),
    );

    final first = await service.generateProgram(
      userId: 'member-1',
      guest: false,
      requestId: 'request-same',
      intake: _intake(),
      catalog: catalog,
    );
    final second = await service.generateProgram(
      userId: 'member-1',
      guest: false,
      requestId: 'request-same',
      intake: _intake(),
      catalog: catalog,
    );

    expect(second.id, first.id);
    expect(second.quotaCommitted, isTrue);
    expect(aiCalls, 1);
    expect(quota.checkCalls, 1);
    expect(quota.commitCalls, 1);
    expect(repository.saveCalls, 1);
  });

  test('invalid Gemini JSON does not persist a plan or commit quota', () async {
    final repository = _MemoryRepository();
    final quota = _QuotaGateway();
    final service = FitnessTrainingService(
      repository: repository,
      quotaGateway: quota,
      currentUserId: () => 'member-1',
      now: () => DateTime(2026, 10, 5, 8),
      aiClientFactory: (_) => _FakeAiClient(() => 'not json'),
    );

    await expectLater(
      service.generateProgram(
        userId: 'member-1',
        guest: false,
        requestId: 'request-invalid',
        intake: _intake(),
        catalog: catalog,
      ),
      throwsA(isA<FitnessProgramValidationException>()),
    );
    expect(repository.program, isNull);
    expect(quota.commitCalls, 0);
  });

  test(
    'quota denial stops before Gemini and preserves existing state',
    () async {
      final repository = _MemoryRepository();
      final quota = _QuotaGateway(allowed: false);
      var aiCalls = 0;
      final service = FitnessTrainingService(
        repository: repository,
        quotaGateway: quota,
        currentUserId: () => 'member-1',
        aiClientFactory: (_) => _FakeAiClient(() {
          aiCalls++;
          return '{}';
        }),
      );

      await expectLater(
        service.generateProgram(
          userId: 'member-1',
          guest: false,
          requestId: 'request-denied',
          intake: _intake(),
          catalog: catalog,
        ),
        throwsA(isA<PersonalScheduleQuotaExceededException>()),
      );
      expect(aiCalls, 0);
      expect(quota.commitCalls, 0);
      expect(repository.program, isNull);
    },
  );

  test('guest quota denial stops before Gemini', () async {
    final repository = _MemoryRepository(guestAvailable: false);
    var aiCalls = 0;
    final service = FitnessTrainingService(
      repository: repository,
      currentUserId: () => null,
      aiClientFactory: (_) => _FakeAiClient(() {
        aiCalls++;
        return '{}';
      }),
    );

    await expectLater(
      service.generateProgram(
        userId: 'guest-1',
        guest: true,
        requestId: 'guest-request',
        intake: _intake(),
        catalog: catalog,
      ),
      throwsA(isA<FitnessTrainingGuestQuotaExceededException>()),
    );
    expect(aiCalls, 0);
    expect(repository.saveCalls, 0);
    expect(repository.program, isNull);
  });

  test(
    'unknown food restrictions do not block or enter workout AI request',
    () async {
      final repository = _MemoryRepository();
      String? prompt;
      final service = FitnessTrainingService(
        repository: repository,
        quotaGateway: _QuotaGateway(),
        currentUserId: () => 'member-1',
        now: () => DateTime(2026, 10, 5, 8),
        validator: _AcceptingValidator(),
        aiClientFactory: (_) => _FakeAiClient(
          () => '{"days":[]}',
          onRequest: (contents) => prompt = contents.single.text,
        ),
      );

      await service.generateProgram(
        userId: 'member-1',
        guest: false,
        requestId: 'workout-only',
        intake: _intake(),
        catalog: catalog,
      );

      final payload = jsonDecode(prompt!.split('DATA=').last) as Map;
      final profile = payload['profile'] as Map;
      expect(prompt!.toLowerCase(), isNot(contains('allergen')));
      expect(prompt!.toLowerCase(), isNot(contains('recipe')));
      expect(prompt!.toLowerCase(), isNot(contains('meal')));
      expect(prompt!.toLowerCase(), isNot(contains('sleep')));
      expect(profile, isNot(contains('excluded_allergens')));
      expect(profile, isNot(contains('available_food_groups')));
      expect(profile, isNot(contains('meal_times')));
      expect(profile, isNot(contains('sleep_time')));
      expect(payload, isNot(contains('available_recipes')));
      expect(repository.program!.intake.mealTimes, isEmpty);
      expect(repository.program!.intake.excludedAllergens, isEmpty);
      expect(repository.program!.intake.availableFoodGroups, isEmpty);
      expect(repository.program!.intake.sleepTime, isEmpty);
      expect(repository.saveCalls, 1);
    },
  );

  test('schedule conflict stops before quota and Gemini', () async {
    final repository = _MemoryRepository()
      ..conflicts = [
        FitnessScheduleConflict(
          workoutStartAt: DateTime(2026, 10, 5, 17, 30),
          workoutEndAt: DateTime(2026, 10, 5, 18, 15),
          itemTitle: 'Cuộc hẹn',
          itemStartAt: DateTime(2026, 10, 5, 18),
          itemEndAt: DateTime(2026, 10, 5, 18, 30),
        ),
      ];
    final quota = _QuotaGateway();
    var aiCalls = 0;
    final service = FitnessTrainingService(
      repository: repository,
      quotaGateway: quota,
      currentUserId: () => 'member-1',
      now: () => DateTime(2026, 10, 5, 8),
      aiClientFactory: (_) => _FakeAiClient(() {
        aiCalls++;
        return '{}';
      }),
    );

    await expectLater(
      service.generateProgram(
        userId: 'member-1',
        guest: false,
        requestId: 'conflicting-request',
        intake: _intake(),
        catalog: catalog,
      ),
      throwsA(isA<FitnessScheduleConflictException>()),
    );
    expect(aiCalls, 0);
    expect(quota.checkCalls, 0);
    expect(repository.saveCalls, 0);
  });

  test('replan conflict leaves active program check-in untouched', () async {
    final repository = _MemoryRepository()
      ..conflicts = [
        FitnessScheduleConflict(
          workoutStartAt: DateTime(2026, 10, 12, 17, 30),
          workoutEndAt: DateTime(2026, 10, 12, 18, 15),
          itemTitle: 'Lịch khác',
          itemStartAt: DateTime(2026, 10, 12, 17, 30),
          itemEndAt: DateTime(2026, 10, 12, 18),
        ),
      ];
    final quota = _QuotaGateway();
    var aiCalls = 0;
    final service = FitnessTrainingService(
      repository: repository,
      quotaGateway: quota,
      currentUserId: () => 'member-1',
      now: () => DateTime(2026, 10, 5, 8),
      aiClientFactory: (_) => _FakeAiClient(() {
        aiCalls++;
        return '{}';
      }),
    );
    final active = FitnessTrainingProgram(
      id: 'active-1',
      userId: 'member-1',
      requestId: 'active-request',
      status: FitnessProgramStatus.active,
      activeWeek: 1,
      quotaCommitted: true,
      startDate: DateTime(2026, 10, 5),
      intake: _intake(),
      days: const [],
      checkIns: const [],
      createdAt: DateTime.utc(2026, 10, 5),
      updatedAt: DateTime.utc(2026, 10, 5),
    );

    await expectLater(
      service.replanRemainingWeeks(
        activeProgram: active,
        checkIn: FitnessWeeklyCheckIn(
          week: 1,
          effortScore: 3,
          sorenessScore: 2,
          note: '',
          createdAt: DateTime.utc(2026, 10, 12),
        ),
        requestId: 'replan-request',
        guest: false,
        intake: _intake(),
        catalog: catalog,
      ),
      throwsA(isA<FitnessScheduleConflictException>()),
    );
    expect(repository.saveCheckInCalls, 0);
    expect(quota.checkCalls, 0);
    expect(aiCalls, 0);
  });

  test('applying preview with a changed time does not call AI again', () async {
    final repository = _MemoryRepository();
    final preview = FitnessTrainingProgram(
      id: 'preview-1',
      userId: 'guest-1',
      requestId: 'preview-request',
      status: FitnessProgramStatus.preview,
      activeWeek: 1,
      quotaCommitted: true,
      startDate: DateTime(2026, 10, 5),
      intake: _intake(),
      days: const [],
      checkIns: const [],
      createdAt: DateTime.utc(2026, 10, 5),
      updatedAt: DateTime.utc(2026, 10, 5),
    );
    repository.program = preview;
    var aiCalls = 0;
    final service = FitnessTrainingService(
      repository: repository,
      currentUserId: () => null,
      now: () => DateTime(2026, 10, 5, 8),
      aiClientFactory: (_) => _FakeAiClient(() {
        aiCalls++;
        return '{}';
      }),
    );

    final applied = await service.applyWeek(
      userId: 'guest-1',
      program: preview,
      week: 1,
      catalog: catalog,
      today: DateTime(2026, 10, 5, 8),
      workoutTimeOverride: '19:30',
    );

    expect(applied.intake.workoutTime, '19:30');
    expect(aiCalls, 0);
    expect(repository.applyCalls, 1);
  });
}

FitnessTrainingIntake _intake() => FitnessTrainingIntake(
  adultEligible: true,
  goal: 'general_fitness',
  experience: 'beginner',
  venue: 'home',
  equipmentIds: const [],
  trainingWeekdays: const [1, 3, 5],
  sessionMinutes: 45,
  workoutTime: '17:30',
  mealTimes: const ['07:30', '12:00', '19:00'],
  excludedMovementGroups: const [],
  excludedAllergens: const ['unknown:crustacean_shellfish'],
  availableFoodGroups: const ['protein', 'fruit_vegetable'],
  sleepTime: '22:30',
  wakeTime: '06:30',
  heightCm: null,
  weightKg: null,
  sexCode: null,
  activityLevel: null,
  bmi: 24.2,
  bmrKcal: 1450,
  tdeeKcal: 1994,
);

class _FakeAiClient implements AiTextClient {
  _FakeAiClient(this.respond, {this.onRequest});

  final String Function() respond;
  final void Function(List<GeminiContent> contents)? onRequest;

  @override
  Future<String> generateText({
    required String model,
    required List<GeminiContent> contents,
    required GeminiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async {
    onRequest?.call(contents);
    return respond();
  }

  @override
  Stream<String> streamText({
    required String model,
    required List<GeminiContent> contents,
    required GeminiGenerationConfig generationConfig,
    String? systemInstruction,
  }) => Stream.value('');
}

class _QuotaGateway implements PersonalScheduleQuotaGateway {
  _QuotaGateway({this.allowed = true});

  final bool allowed;
  int checkCalls = 0;
  int commitCalls = 0;

  @override
  Future<PersonalScheduleQuotaDecision> checkGeneration({
    required String userId,
    required String requestId,
    required DateTime at,
  }) async {
    checkCalls++;
    return allowed
        ? const PersonalScheduleQuotaDecision.allowed()
        : const PersonalScheduleQuotaDecision.denied();
  }

  @override
  Future<void> commitGeneration({
    required String userId,
    required String requestId,
    required DateTime at,
  }) async {
    commitCalls++;
  }
}

class _MemoryRepository implements FitnessTrainingRepository {
  _MemoryRepository({this.guestAvailable = true});

  final bool guestAvailable;
  FitnessTrainingProgram? program;
  int saveCalls = 0;
  int saveCheckInCalls = 0;
  int applyCalls = 0;
  List<FitnessScheduleConflict> conflicts = const [];

  @override
  Future<bool> guestInitialPlanAvailable(String userId) async => guestAvailable;

  @override
  Future<List<FitnessTrainingProgram>> loadPrograms(String userId) async =>
      program == null ? const [] : [program!];

  @override
  Future<FitnessTrainingProgram?> findByRequestId(
    String userId,
    String requestId,
  ) async => program?.requestId == requestId ? program : null;

  @override
  Future<FitnessTrainingProgram> savePreview(
    FitnessTrainingProgram value, {
    required bool guest,
  }) async {
    saveCalls++;
    program = value.copyWith(quotaCommitted: guest);
    return program!;
  }

  @override
  Future<void> markQuotaCommitted({
    required String userId,
    required String programId,
  }) async {
    program = program?.copyWith(quotaCommitted: true);
  }

  @override
  Future<FitnessTrainingProgram> saveCheckIn({
    required String userId,
    required String programId,
    required FitnessWeeklyCheckIn checkIn,
  }) async {
    saveCheckInCalls++;
    return program!;
  }

  @override
  Future<List<FitnessScheduleConflict>> findScheduleConflicts({
    required String userId,
    required List<FitnessWorkoutScheduleSlot> slots,
    required DateTime now,
  }) async => conflicts;

  @override
  Future<FitnessTrainingProgram> applyWeek({
    required String userId,
    required String programId,
    required int week,
    required DateTime today,
    required FitnessTrainingCatalog catalog,
    String? workoutTimeOverride,
  }) async {
    applyCalls++;
    final current = program!;
    if (workoutTimeOverride == null) return current;
    return current.copyWith(
      intake: current.intake.copyWith(workoutTime: workoutTimeOverride),
    );
  }
}

class _AcceptingValidator extends FitnessProgramValidator {
  @override
  FitnessTrainingProgram parse({
    required String response,
    required String userId,
    required String requestId,
    required String programId,
    required String status,
    required bool quotaCommitted,
    required FitnessTrainingIntake intake,
    required FitnessTrainingCatalog catalog,
    required DateTime startDate,
    required DateTime now,
    int firstDayIndex = 0,
    List<FitnessProgramDay> preservedDays = const [],
    List<FitnessWeeklyCheckIn> checkIns = const [],
    String? parentProgramId,
  }) => FitnessTrainingProgram(
    id: programId,
    userId: userId,
    requestId: requestId,
    status: status,
    activeWeek: 1,
    quotaCommitted: quotaCommitted,
    startDate: startDate,
    intake: intake,
    days: const [],
    checkIns: checkIns,
    createdAt: now,
    updatedAt: now,
    parentProgramId: parentProgramId,
  );
}
