import 'dart:convert';
import 'dart:math';

import 'package:nano_app/app_versions/v1/services/ai/gemini_rest_client.dart';
import 'package:nano_app/app_versions/v1/services/ai/nabi_ai_backend_client.dart';
import 'package:nano_app/app_versions/v1/services/ai/personal_schedule_quota_gateway.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

import '../data/datasources/fitness_training_catalog_asset_datasource.dart';
import '../domain/entities/fitness_training_catalog.dart';
import '../domain/entities/fitness_schedule_conflict.dart';
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
    final firstDayIndex = checkIn.week * 7;
    await _ensureNoScheduleConflicts(
      userId: activeProgram.userId,
      intake: intake,
      startDate: activeProgram.startDate,
      firstDayIndex: firstDayIndex,
    );
    if (guest &&
        !await repository.guestInitialPlanAvailable(activeProgram.userId)) {
      throw const FitnessTrainingGuestQuotaExceededException();
    }
    final withoutWeek = activeProgram.checkIns
        .where((item) => item.week != checkIn.week)
        .toList(growable: false);
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
        preservedDays: activeProgram.days,
        checkIns: [...withoutWeek, checkIn],
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
    String? workoutTimeOverride,
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
      workoutTimeOverride: workoutTimeOverride,
    );
  }

  Future<FitnessWorkoutTimeResolution> resolveWorkoutTime({
    required String userId,
    required FitnessTrainingIntake intake,
    required DateTime startDate,
    required int firstDayIndex,
    required String requestedTime,
  }) {
    final start = _dateOnly(startDate);
    final dates = <DateTime>[];
    for (
      var index = firstDayIndex;
      index < firstDayIndex + 7 && index < 28;
      index++
    ) {
      final date = start.add(Duration(days: index));
      if (intake.trainingWeekdays.contains(date.weekday)) dates.add(date);
    }
    return _resolveWorkoutTimeAcrossDates(
      userId: userId,
      dates: dates,
      sessionMinutes: intake.sessionMinutes,
      requestedTime: requestedTime,
    );
  }

  Future<FitnessWorkoutTimeResolution> resolveWorkoutTimeForProgramWeek({
    required String userId,
    required FitnessTrainingProgram program,
    required int week,
    required String requestedTime,
  }) {
    final baseIndex = (week - 1) * 7;
    final dates = [
      for (final day in program.days)
        if (day.dayIndex >= baseIndex &&
            day.dayIndex < baseIndex + 7 &&
            !day.isRestDay &&
            day.exercises.isNotEmpty)
          day.date,
    ];
    return _resolveWorkoutTimeAcrossDates(
      userId: userId,
      dates: dates,
      sessionMinutes: program.intake.sessionMinutes,
      requestedTime: requestedTime,
    );
  }

  Future<FitnessWorkoutTimeResolution> _resolveWorkoutTimeAcrossDates({
    required String userId,
    required List<DateTime> dates,
    required int sessionMinutes,
    required String requestedTime,
  }) async {
    final requestedMinutes = _minutesOfDay(requestedTime);
    if (requestedMinutes == null) {
      throw const FitnessProgramValidationException('workout_time');
    }

    final alternatives =
        fitnessWorkoutTimeOptions
            .where((time) => time != requestedTime)
            .toList(growable: false)
          ..sort((left, right) {
            final leftMinutes = _minutesOfDay(left) ?? requestedMinutes;
            final rightMinutes = _minutesOfDay(right) ?? requestedMinutes;
            final distance = (leftMinutes - requestedMinutes).abs().compareTo(
              (rightMinutes - requestedMinutes).abs(),
            );
            return distance != 0 ? distance : left.compareTo(right);
          });
    final candidateTimes = [requestedTime, ...alternatives];
    final nowAt = now();
    final slotsByTime = <String, List<FitnessWorkoutScheduleSlot>>{
      for (final time in candidateTimes)
        time: _slotsForDates(
          dates: dates,
          sessionMinutes: sessionMinutes,
          time: time,
          nowAt: nowAt,
        ),
    };
    final conflictsByTime = await repository.findScheduleConflictsByWorkoutTime(
      userId: userId,
      slotsByTime: slotsByTime,
      now: nowAt,
    );
    final conflicts = conflictsByTime[requestedTime];
    if (conflicts == null) {
      throw StateError('Schedule conflict query omitted the requested time.');
    }
    if (conflicts.isEmpty) {
      return FitnessWorkoutTimeResolution(
        requestedTime: requestedTime,
        conflicts: conflicts,
      );
    }

    String? suggestedTime;
    for (final alternative in alternatives) {
      final candidateConflicts = conflictsByTime[alternative];
      if (candidateConflicts == null) {
        throw StateError('Schedule conflict query omitted $alternative.');
      }
      if (candidateConflicts.isEmpty) {
        suggestedTime = alternative;
        break;
      }
    }
    return FitnessWorkoutTimeResolution(
      requestedTime: requestedTime,
      suggestedTime: suggestedTime,
      conflicts: conflicts,
    );
  }

  List<FitnessWorkoutScheduleSlot> _slotsForDates({
    required List<DateTime> dates,
    required int sessionMinutes,
    required String time,
    required DateTime nowAt,
  }) {
    final minutes = _minutesOfDay(time);
    if (minutes == null) {
      throw const FitnessProgramValidationException('workout_time');
    }
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final slots = <FitnessWorkoutScheduleSlot>[];
    for (final date in dates) {
      final startAt = DateTime(date.year, date.month, date.day, hour, minute);
      if (startAt.isBefore(nowAt)) continue;
      slots.add(
        FitnessWorkoutScheduleSlot(
          startAt: startAt,
          endAt: startAt.add(Duration(minutes: sessionMinutes)),
        ),
      );
    }
    return slots;
  }

  int? _minutesOfDay(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return hour * 60 + minute;
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
    final workoutIntake = intake.forWorkoutOnly();
    if (requestId.trim().isEmpty || userId.trim().isEmpty) {
      throw const FormatException('Request identity is required.');
    }
    final existing = await repository.findByRequestId(userId, requestId);
    if (existing != null) {
      return _ensureQuotaCommitted(existing, guest: guest);
    }

    await _ensureNoScheduleConflicts(
      userId: userId,
      intake: workoutIntake,
      startDate: startDate,
      firstDayIndex: firstDayIndex,
    );

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
      venue: workoutIntake.venue,
      equipmentIds: workoutIntake.equipmentIds.toSet(),
      excludedMovementGroups: workoutIntake.excludedMovementGroups.toSet(),
    );
    if (exercises.isEmpty) {
      throw const FitnessProgramValidationException('no_safe_exercises');
    }

    final response = await aiClientFactory(operation).generateText(
      model: model,
      contents: [
        GeminiContent.user(
          _prompt(
            intake: workoutIntake,
            exercises: exercises,
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
      intake: workoutIntake,
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

  Future<void> _ensureNoScheduleConflicts({
    required String userId,
    required FitnessTrainingIntake intake,
    required DateTime startDate,
    required int firstDayIndex,
  }) async {
    final resolution = await resolveWorkoutTime(
      userId: userId,
      intake: intake,
      startDate: startDate,
      firstDayIndex: firstDayIndex,
      requestedTime: intake.workoutTime,
    );
    if (!resolution.hasConflicts) return;
    throw FitnessWorkoutTimeResolutionRequired(resolution);
  }

  String _prompt({
    required FitnessTrainingIntake intake,
    required List<FitnessExercise> exercises,
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
    final payload = <String, Object?>{
      'profile': intake.toAiJson(),
      'program': {
        'start_date': _dateKey(startDate),
        'first_day_index': firstDayIndex,
        'last_day_index': endDay,
      },
      'available_exercises': exerciseRows,
      if (checkIn != null)
        'weekly_feedback': {
          'week': checkIn.week,
          'effort_score': checkIn.effortScore,
          'soreness_score': checkIn.sorenessScore,
        },
    };
    return '''
Tạo hoặc điều chỉnh chương trình luyện tập wellness 4 tuần theo dữ liệu JSON dưới đây.
Chỉ được dùng exercise_id có trong catalog gửi kèm. Không tạo ID hoặc bài tập mới.
Người dùng chọn tập ${intake.venue == 'home' ? 'tại nhà' : 'ở phòng gym'}; chỉ dùng đúng thiết bị và nhóm vận động còn lại sau khi lọc.
Ngày tập lặp theo các thứ ${intake.trainingWeekdays.join(', ')} (1=Thứ Hai ... 7=Chủ Nhật). Ngày khác phải là ngày nghỉ.
Các thông số sets/reps/rest hoặc duration phải nằm trong bounds của bài tập. Giữ mức độ vừa với kinh nghiệm và session_minutes.
Chỉ trả về JSON thuần, không markdown, theo cấu trúc:
{"days":[{"day_index":0,"workout":{"is_rest_day":false,"exercises":[{"exercise_id":"...","sets":2,"reps":8,"rest_seconds":60,"duration_minutes":null}]}}]}
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
You create structured workout-only wellness schedules using only the supplied exercise catalog.
Treat movement restrictions and the allowlisted exercise catalog as mandatory. Never invent exercise IDs.
Return only valid JSON matching the requested workout-day shape with no extra keys. Do not include personal identifiers, diagnoses, or treatment advice.
''';
