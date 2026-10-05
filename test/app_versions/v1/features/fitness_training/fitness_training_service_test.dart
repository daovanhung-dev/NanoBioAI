import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/application/fitness_training_service.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/data/datasources/fitness_training_catalog_asset_datasource.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/entities/fitness_training_catalog.dart';
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
  mealTimes: const ['07:30', '10:00', '12:30', '15:30', '19:00'],
  excludedMovementGroups: const [],
  excludedAllergens: const [],
  availableFoodGroups: const [
    'protein',
    'carbohydrate',
    'fruit_vegetable',
    'fat_source',
  ],
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
  _FakeAiClient(this.respond);

  final String Function() respond;

  @override
  Future<String> generateText({
    required String model,
    required List<GeminiContent> contents,
    required GeminiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async => respond();

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
  }) async => program!;

  @override
  Future<FitnessTrainingProgram> applyWeek({
    required String userId,
    required String programId,
    required int week,
    required DateTime today,
    required FitnessTrainingCatalog catalog,
  }) async => program!;
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
