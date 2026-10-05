import 'dart:convert';
import 'dart:math';

import 'package:nano_app/app_versions/v1/services/ai/gemini_rest_client.dart';
import 'package:nano_app/app_versions/v1/services/ai/nabi_ai_backend_client.dart';
import 'package:nano_app/app_versions/v1/services/ai/personal_schedule_quota_gateway.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

import '../data/datasources/fitness_training_catalog_asset_datasource.dart';
import '../domain/entities/fitness_training_catalog.dart';
import '../domain/entities/fitness_training_program.dart';
import '../domain/repositories/fitness_training_repository.dart';
import '../domain/services/fitness_program_validator.dart';

class FitnessTrainingService {
  FitnessTrainingService({
    required this.repository,
    this.catalogDatasource = const FitnessTrainingCatalogAssetDatasource(),
    PersonalScheduleQuotaGateway? quotaGateway,
    AiTextClient Function(String operation)? aiClientFactory,
    String? Function()? currentUserId,
    DateTime Function()? now,
    this.validator = const FitnessProgramValidator(),
    String Function()? idGenerator,
  }) : quotaGateway =
           quotaGateway ?? const TrustedBackendPersonalScheduleQuotaGateway(),
       aiClientFactory = aiClientFactory ?? _defaultClient,
       currentUserId = currentUserId ?? currentSupabaseUserIdOrNull,
       now = now ?? DateTime.now,
       idGenerator = idGenerator ?? _uuidV4;

  static const model = 'gemini-2.5-flash';
  static const _generateOperation = 'fitness_training_generate';
  static const _replanOperation = 'fitness_training_replan';
  static final Map<String, Future<FitnessTrainingProgram>> _inFlight = {};

  final FitnessTrainingRepository repository;
  final FitnessTrainingCatalogAssetDatasource catalogDatasource;
  final PersonalScheduleQuotaGateway quotaGateway;
  final AiTextClient Function(String operation) aiClientFactory;
  final String? Function() currentUserId;
  final DateTime Function() now;
  final FitnessProgramValidator validator;
  final String Function() idGenerator;

  Future<FitnessTrainingCatalog> loadCatalog() => catalogDatasource.load();

  Future<List<FitnessTrainingProgram>> loadPrograms(String userId) =>
      repository.loadPrograms(userId);

  Future<FitnessTrainingProgram> generateProgram({
    required String userId,
    required bool guest,
    required String requestId,
    required FitnessTrainingIntake intake,
    required FitnessTrainingCatalog catalog,
  }) => _singleFlight(
    '$userId:$requestId',
    () => _generate(
      userId: userId,
      guest: guest,
      requestId: requestId,
      intake: intake,
      catalog: catalog,
      startDate: _dateOnly(now()),
      firstDayIndex: 0,
      operation: _generateOperation,
    ),
  );

  Future<FitnessTrainingProgram> replanRemainingWeeks({
    required FitnessTrainingProgram activeProgram,
    required FitnessWeeklyCheckIn checkIn,
    required String requestId,
    required bool guest,
    required FitnessTrainingIntake intake,
    required FitnessTrainingCatalog catalog,
  }) async {
    if (checkIn.week < 1 || checkIn.week > 3) {
      throw const FitnessProgramValidationException('replan_window');
    }
    if (checkIn.effortScore < 1 ||
        checkIn.effortScore > 5 ||
        checkIn.sorenessScore < 1 ||
        checkIn.sorenessScore > 5) {
      throw const FitnessProgramValidationException('checkin_range');
    }
    if (guest &&
        !await repository.guestInitialPlanAvailable(activeProgram.userId)) {
      throw const FitnessTrainingGuestQuotaExceededException();
    }
    final checkedInProgram = await repository.saveCheckIn(
      userId: activeProgram.userId,
      programId: activeProgram.id,
      checkIn: checkIn,
    );
    final firstDayIndex = checkIn.week * 7;
    return _singleFlight(
      '${activeProgram.userId}:$requestId',
      () => _generate(
        userId: activeProgram.userId,
        guest: guest,
        requestId: requestId,
        intake: intake,
        catalog: catalog,
        startDate: activeProgram.startDate,
        firstDayIndex: firstDayIndex,
        preservedDays: checkedInProgram.days,
        checkIns: checkedInProgram.checkIns,
        parentProgramId: activeProgram.id,
        checkIn: checkIn,
        operation: _replanOperation,
      ),
    );
  }

  Future<FitnessTrainingProgram> applyWeek({
    required String userId,
    required FitnessTrainingProgram program,
    required int week,
    required FitnessTrainingCatalog catalog,
    required DateTime today,
  }) async {
    final ready = await _ensureQuotaCommitted(
      program,
      guest: currentUserId() == null,
    );
    return repository.applyWeek(
      userId: userId,
      programId: ready.id,
      week: week,
      today: today,
      catalog: catalog,
    );
  }

  Future<FitnessTrainingProgram> _generate({
    required String userId,
    required bool guest,
    required String requestId,
    required FitnessTrainingIntake intake,
    required FitnessTrainingCatalog catalog,
    required DateTime startDate,
    required int firstDayIndex,
    required String operation,
    List<FitnessProgramDay> preservedDays = const [],
    List<FitnessWeeklyCheckIn> checkIns = const [],
    String? parentProgramId,
    FitnessWeeklyCheckIn? checkIn,
  }) async {
    if (!intake.adultEligible) {
      throw const FitnessProgramValidationException('adult_gate');
    }
    if (requestId.trim().isEmpty || userId.trim().isEmpty) {
      throw const FormatException('Request identity is required.');
    }
    final existing = await repository.findByRequestId(userId, requestId);
    if (existing != null) {
      return _ensureQuotaCommitted(existing, guest: guest);
    }

    final authUserId = currentUserId();
    if (!guest) {
      if (authUserId == null || authUserId != userId) {
        throw const PersonalScheduleQuotaUnavailableException();
      }
      final decision = await quotaGateway.checkGeneration(
        userId: authUserId,
        requestId: requestId,
        at: now(),
      );
      if (!decision.allowed) {
        throw PersonalScheduleQuotaExceededException(resetAt: decision.resetAt);
      }
    } else if (!await repository.guestInitialPlanAvailable(userId)) {
      throw const FitnessTrainingGuestQuotaExceededException();
    }

    final exercises = catalog.eligibleExercises(
      venue: intake.venue,
      equipmentIds: intake.equipmentIds.toSet(),
      excludedMovementGroups: intake.excludedMovementGroups.toSet(),
    );
    final recipes = catalog.eligibleRecipes(
      excludedAllergens: intake.excludedAllergens.toSet(),
      availableFoodGroups: intake.availableFoodGroups.toSet(),
    );
    if (exercises.isEmpty) {
      throw const FitnessProgramValidationException('no_safe_exercises');
    }
    for (final slot in FitnessProgramValidator.mealSlots) {
      if (!recipes.any((recipe) => recipe.mealSlot == slot)) {
        throw const FitnessProgramValidationException('no_safe_meals');
      }
    }

    final response = await aiClientFactory(operation).generateText(
      model: model,
      contents: [
        GeminiContent.user(
          _prompt(
            intake: intake,
            exercises: exercises,
            recipes: recipes,
            startDate: startDate,
            firstDayIndex: firstDayIndex,
            checkIn: checkIn,
          ),
        ),
      ],
      generationConfig: const GeminiGenerationConfig(
        candidateCount: 1,
        maxOutputTokens: 12288,
        temperature: 0.2,
        responseMimeType: 'application/json',
      ),
      systemInstruction: _systemInstruction,
    );

    final stamp = now().toUtc();
    final program = validator.parse(
      response: response,
      userId: userId,
      requestId: requestId,
      programId: idGenerator(),
      status: FitnessProgramStatus.preview,
      quotaCommitted: guest,
      intake: intake,
      catalog: catalog,
      startDate: startDate,
      now: stamp,
      firstDayIndex: firstDayIndex,
      preservedDays: preservedDays,
      checkIns: checkIns,
      parentProgramId: parentProgramId,
    );
    final saved = await repository.savePreview(program, guest: guest);
    return _ensureQuotaCommitted(saved, guest: guest);
  }

  Future<FitnessTrainingProgram> _ensureQuotaCommitted(
    FitnessTrainingProgram program, {
    required bool guest,
  }) async {
    if (guest || program.quotaCommitted) return program;
    final userId = currentUserId();
    if (userId == null || userId != program.userId) {
      throw const PersonalScheduleQuotaUnavailableException();
    }
    await quotaGateway.commitGeneration(
      userId: userId,
      requestId: program.requestId,
      at: now(),
    );
    await repository.markQuotaCommitted(
      userId: program.userId,
      programId: program.id,
    );
    return program.copyWith(quotaCommitted: true, updatedAt: now().toUtc());
  }

  String _prompt({
    required FitnessTrainingIntake intake,
    required List<FitnessExercise> exercises,
    required List<FitnessRecipe> recipes,
    required DateTime startDate,
    required int firstDayIndex,
    FitnessWeeklyCheckIn? checkIn,
  }) {
    final endDay = 27;
    final exerciseRows = exercises
        .map(
          (exercise) => {
            'id': exercise.id,
            'name': exercise.name,
            'venue': exercise.venue,
            'equipment_ids': exercise.gearIds,
            'muscle_groups': exercise.muscleGroups,
            'movement_type': exercise.movementType,
            'bounds': exercise.bounds,
          },
        )
        .toList(growable: false);
    final recipeRows = recipes
        .map(
          (recipe) => {
            'id': recipe.id,
            'meal_slot': recipe.mealSlot,
            'allergens': recipe.allergens,
            'ingredient_ids': recipe.ingredients
                .map((item) => item.ingredientId)
                .toList(growable: false),
            'nutrition_per_serving': recipe.nutrientsPerServing,
          },
        )
        .toList(growable: false);
    final payload = <String, Object?>{
      'profile': intake.toJson(),
      'program': {
        'start_date': _dateKey(startDate),
        'first_day_index': firstDayIndex,
        'last_day_index': endDay,
      },
      'available_exercises': exerciseRows,
      'available_recipes': recipeRows,
      if (checkIn != null)
        'weekly_feedback': {
          'week': checkIn.week,
          'effort_score': checkIn.effortScore,
          'soreness_score': checkIn.sorenessScore,
        },
    };
    return '''
Tạo hoặc điều chỉnh chương trình luyện tập wellness 4 tuần theo dữ liệu JSON dưới đây.
Chỉ được dùng exercise_id và recipe_id có trong catalog gửi kèm. Không tạo ID, bài tập, món ăn hay nguyên liệu mới.
Người dùng chọn tập ${intake.venue == 'home' ? 'tại nhà' : 'ở phòng gym'}; chỉ dùng đúng thiết bị và nhóm vận động còn lại sau khi lọc.
Ngày tập lặp theo các thứ ${intake.trainingWeekdays.join(', ')} (1=Thứ Hai ... 7=Chủ Nhật). Ngày khác phải là ngày nghỉ.
Mỗi ngày phải có đủ 5 meal_slot: breakfast, morning_snack, lunch, afternoon_snack, dinner; recipe phải đúng meal_slot.
Không tạo lời khuyên chẩn đoán/điều trị, không tự đặt con số dinh dưỡng, calories hoặc macro. Số liệu món ăn là tham khảo từ catalog.
Các thông số sets/reps/rest hoặc duration phải nằm trong bounds của bài tập. Giữ mức độ vừa với kinh nghiệm và session_minutes.
Chỉ trả về JSON thuần, không markdown, theo cấu trúc:
{"days":[{"day_index":0,"workout":{"is_rest_day":false,"exercises":[{"exercise_id":"...","sets":2,"reps":8,"rest_seconds":60,"duration_minutes":null}]},"meals":[{"meal_slot":"breakfast","recipe_id":"...","servings":1.0}]}]}
Trả đúng các day_index từ $firstDayIndex đến $endDay. Với bài sức mạnh, điền sets/reps/rest_seconds và duration_minutes=null. Với cardio, điền sets/reps/rest_seconds=null và duration_minutes trong bounds.
Không đưa ngày sinh, tên, ghi chú hồ sơ hoặc thông tin định danh vào câu trả lời.
DATA=${jsonEncode(payload)}
'''
        .trim();
  }

  Future<FitnessTrainingProgram> _singleFlight(
    String key,
    Future<FitnessTrainingProgram> Function() action,
  ) async {
    final active = _inFlight[key];
    if (active != null) return active;
    final future = action();
    _inFlight[key] = future;
    try {
      return await future;
    } finally {
      if (identical(_inFlight[key], future)) _inFlight.remove(key);
    }
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static AiTextClient _defaultClient(String operation) =>
      NabiAiBackendClient(operation: operation);

  static String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}

const _systemInstruction = '''
You create structured wellness fitness schedules using only the supplied catalog.
Treat every user restriction and allowlisted catalog as mandatory. Never invent catalog IDs or nutrition facts.
Return valid JSON matching the requested shape. Do not include personal identifiers or medical diagnosis/treatment.
''';
