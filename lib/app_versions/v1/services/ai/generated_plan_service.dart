import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:nano_app/core/storage/localdb/datasources/ai_catalog_local_datasource.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/data/datasources/daily_routine_preferences_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/domain/entities/daily_routine_preferences.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/data/datasources/exercise_planning_preferences_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/domain/entities/exercise_planning_preferences.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/domain/entities/daily_health_profile_entity.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/domain/repositories/daily_routine_preferences_repository.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/domain/repositories/daily_routine_preferences_repository_impl.dart';
import 'package:nano_app/app_versions/v1/features/daily_routine/domain/services/schedule_timing_resolver.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/data/datasources/daily_health_tracking_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/datasources/lifestyle_schedule_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/datasources/schedule_horizon_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/schedule_horizon.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/repositories/schedule_horizon_reader.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/services/lifestyle_schedule_window_policy.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/lifestyle_schedule_timeline_builder.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/exercise_tasks_ai_normalizer.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/services/exercise_candidate_selector.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_ai_normalizer.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/services/meal_candidate_selector.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/data/datasources/nutrition_profile_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/domain/entities/nutrition_profile_entity.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/application/schedule_reward_online_gateway.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/application/schedule_reward_eligibility_projection_store.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_exceptions.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_generation_result.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_service.dart';
import 'package:nano_app/app_versions/v1/services/ai/schedule_ai_personalization_context.dart';
import 'package:nano_app/app_versions/v1/services/ai/generated_plan_request_store.dart';
import 'package:nano_app/app_versions/v1/services/ai/personal_schedule_quota_gateway.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_bootstrap.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

class DashboardGenerationAuthRequiredException implements Exception {
  static const userMessage =
      'Bạn cần đăng nhập để Nabi tạo dữ liệu lịch trình 7 ngày mới nhé.';

  const DashboardGenerationAuthRequiredException();

  @override
  String toString() => userMessage;
}

void requireAuthenticatedGeneratedPlanUser(String? userId) {
  if (userId == null || userId.trim().isEmpty) {
    throw const DashboardGenerationAuthRequiredException();
  }
}

class GuestInitialPlanAlreadyUsedException implements Exception {
  static const userMessage =
      'Lượt tạo lịch đầu tiên của khách đã được dùng rồi. Bạn đăng nhập để tiếp tục tạo lịch mới nhé.';

  const GuestInitialPlanAlreadyUsedException();

  @override
  String toString() => userMessage;
}

class ScheduleCandidatesUnavailableException implements Exception {
  final String userMessage;

  const ScheduleCandidatesUnavailableException(this.userMessage);

  @override
  String toString() => userMessage;
}

class GeneratedPlanResult {
  final String requestId;
  final DateTime startDate;
  final int days;
  final int mealCount;
  final int exerciseCount;
  final int scheduleItemCount;
  final bool reusedExistingRequest;
  final PlanGenerationSource generationSource;
  final List<ScheduleRewardEligibilityItem> rewardEligibilityItems;

  const GeneratedPlanResult({
    this.requestId = '',
    required this.startDate,
    required this.days,
    required this.mealCount,
    required this.exerciseCount,
    required this.scheduleItemCount,
    this.reusedExistingRequest = false,
    this.generationSource = PlanGenerationSource.unknown,
    this.rewardEligibilityItems = const [],
  });
}

@immutable
class GeneratedPlanProgress {
  final int totalDays;
  final List<int> savedDays;

  const GeneratedPlanProgress({
    required this.totalDays,
    this.savedDays = const [],
  });

  int get completedDays => savedDays.length;

  int get percentComplete => totalDays <= 0
      ? 0
      : ((completedDays * 100) / totalDays).round().clamp(0, 100).toInt();
}

typedef GeneratedPlanProgressCallback =
    void Function(GeneratedPlanProgress progress);

class GeneratedPlanService {
  static const _tag = 'GENERATED_PLAN';
  static final Map<String, Future<GeneratedPlanResult>> _inFlightByUser = {};

  final DashboardRepository dashboardRepository;
  final DailyHealthTrackingLocalDatasource dailyHealthDatasource;
  final LifestyleScheduleLocalDatasource scheduleDatasource;
  final AIService aiService;
  final AiCatalogLocalDatasource catalogDatasource;
  final NutritionProfileLocalDatasource nutritionProfileDatasource;
  final ExercisePlanningPreferencesLocalDatasource
  exercisePreferencesDatasource;
  final PersonalScheduleAiRequestStore requestStore;
  final PersonalScheduleQuotaGateway quotaGateway;
  final ScheduleHorizonReader scheduleHorizonReader;
  final DailyRoutinePreferencesRepository routinePreferencesRepository;
  final ScheduleTimingResolver timingResolver;
  final ScheduleRewardOnlineGateway rewardGateway;
  final ScheduleRewardEligibilityProjectionStore rewardProjectionStore;
  final Future<void> Function() scheduleReminders;
  final String? Function() currentUserId;
  final DateTime Function() now;

  GeneratedPlanService({
    required this.dashboardRepository,
    required this.dailyHealthDatasource,
    required this.scheduleDatasource,
    required this.aiService,
    this.catalogDatasource = const AiCatalogLocalDatasource(),
    this.nutritionProfileDatasource = const NutritionProfileLocalDatasource(),
    this.exercisePreferencesDatasource =
        const ExercisePlanningPreferencesLocalDatasource(),
    PersonalScheduleAiRequestStore? requestStore,
    PersonalScheduleQuotaGateway? quotaGateway,
    ScheduleHorizonReader? scheduleHorizonReader,
    DailyRoutinePreferencesRepository? routinePreferencesRepository,
    this.timingResolver = const ScheduleTimingResolver(),
    ScheduleRewardOnlineGateway? rewardGateway,
    ScheduleRewardEligibilityProjectionStore? rewardProjectionStore,
    Future<void> Function()? scheduleReminders,
    String? Function()? currentUserId,
    DateTime Function()? now,
  }) : scheduleReminders =
           scheduleReminders ??
           NotificationBootstrap.scheduleGeneratedReminders,
       currentUserId = currentUserId ?? currentSupabaseUserIdOrNull,
       requestStore = requestStore ?? LocalPersonalScheduleAiRequestStore(),
       quotaGateway =
           quotaGateway ?? const TrustedBackendPersonalScheduleQuotaGateway(),
       scheduleHorizonReader =
           scheduleHorizonReader ?? const ScheduleHorizonLocalDatasource(),
       routinePreferencesRepository =
           routinePreferencesRepository ??
           const DailyRoutinePreferencesRepositoryImpl(
             datasource: DailyRoutinePreferencesLocalDatasource(),
           ),
       rewardGateway =
           rewardGateway ?? const SupabaseScheduleRewardOnlineGateway(),
       rewardProjectionStore =
           rewardProjectionStore ??
           const SqliteScheduleRewardEligibilityProjectionStore(),
       now = now ?? DateTime.now;

  Future<GeneratedPlanResult> generateNextPlan({
    required String requestId,
    int days = 7,
    DateTime? startDate,
    bool appendAfterExisting = true,
  }) async {
    final authUserId = currentUserId();
    requireAuthenticatedGeneratedPlanUser(authUserId);

    final normalizedRequestId = _normalizeRequestId(requestId);
    final existing = await _existingSucceededResult(
      normalizedRequestId,
      actorMode: GeneratedPlanActorModes.memberNew,
    );
    if (existing != null) return existing;

    final activeRequest = _inFlightByUser[authUserId!];
    if (activeRequest != null) return activeRequest;

    aiService.resetTransientModelCooldowns();
    final request = _generateNextPlanSingleFlight(
      authUserId: authUserId,
      requestId: normalizedRequestId,
      days: days,
      requestedStartDate: startDate,
      appendAfterExisting: appendAfterExisting,
    );
    _inFlightByUser[authUserId] = request;
    try {
      return await request;
    } finally {
      if (identical(_inFlightByUser[authUserId], request)) {
        _inFlightByUser.remove(authUserId);
      }
    }
  }

  Future<GeneratedPlanResult> _generateNextPlanSingleFlight({
    required String authUserId,
    required String requestId,
    required int days,
    required DateTime? requestedStartDate,
    required bool appendAfterExisting,
  }) async {
    final existing = await _existingSucceededResult(
      requestId,
      actorMode: GeneratedPlanActorModes.memberNew,
    );
    if (existing != null) return existing;

    final profile = await dailyHealthDatasource.fetchLatestProfile();
    final horizon = await scheduleHorizonReader.read(
      userId: profile.userId,
      today: LifestyleScheduleWindowPolicy.vietnamNow(),
    );
    if (!horizon.canGenerate) {
      throw PersonalScheduleStillActiveException(horizon.remainingDays);
    }
    var planStartDate = _dateOnly(
      appendAfterExisting
          ? horizon.nextStartDate
          : requestedStartDate ?? horizon.nextStartDate,
    );
    var requestIdForPlan = await requestStore.findIncompleteRequestId(
      userId: profile.userId,
      actorMode: GeneratedPlanActorModes.memberNew,
      startDate: planStartDate,
      days: days,
    );
    requestIdForPlan ??= await requestStore.findIncompleteRequestId(
      userId: profile.userId,
      actorMode: GeneratedPlanActorModes.memberNew,
      days: days,
    );
    if (requestIdForPlan != null) {
      final incomplete = await requestStore.findByRequestId(requestIdForPlan);
      if (incomplete != null &&
          incomplete.userId == profile.userId &&
          incomplete.actorMode == GeneratedPlanActorModes.memberNew &&
          incomplete.days == days &&
          incomplete.startDate != null) {
        planStartDate = _dateOnly(incomplete.startDate!);
      }
    } else {
      requestIdForPlan = requestId;
    }
    final preferences = await routinePreferencesRepository.loadForUser(
      profile.userId,
    );
    if (preferences == null) {
      throw const DailyRoutinePreferencesRequiredException();
    }

    final decision = await quotaGateway.checkGeneration(
      userId: authUserId,
      requestId: requestIdForPlan,
      at: now(),
    );
    if (!decision.allowed) {
      throw PersonalScheduleQuotaExceededException(resetAt: decision.resetAt);
    }

    final result = await _generatePlan(
      actorMode: GeneratedPlanActorModes.memberNew,
      requestId: requestIdForPlan,
      days: days,
      startDate: planStartDate,
      appendAfterExisting: appendAfterExisting,
      markGuestInitialPlanUsed: false,
      routinePreferences: preferences,
    );

    if (result.generationSource.isFullyAiGenerated) {
      await quotaGateway.commitGeneration(
        userId: authUserId,
        requestId: requestIdForPlan,
        at: now(),
      );
    } else {
      AppLogger.info(
        _tag,
        'Skipped member generation quota commit; '
        'source=${result.generationSource.storageValue}',
      );
    }

    if (result.rewardEligibilityItems.isNotEmpty) {
      try {
        await rewardGateway.registerEligibilities(
          requestId: requestIdForPlan,
          items: result.rewardEligibilityItems,
          idempotencyKey: 'eligibility:$requestIdForPlan:v1',
        );
        try {
          await rewardProjectionStore.markRegistered(
            userId: authUserId,
            requestId: requestIdForPlan,
            items: result.rewardEligibilityItems,
          );
        } catch (error) {
          AppLogger.warning(
            _tag,
            'Reward eligibility local projection deferred; '
            'errorType=${error.runtimeType}',
          );
        }
        AppLogger.success(_tag, 'Registered schedule reward eligibility');
      } catch (error) {
        // Lịch đã được tạo và quota đã commit. Không báo thất bại giả; begin
        // completion sẽ thử theo trạng thái server và chỉ cảnh báo không có điểm.
        AppLogger.warning(
          _tag,
          'Reward eligibility registration deferred; '
          'errorType=${error.runtimeType}',
        );
      }
    }

    return result;
  }

  Future<GeneratedPlanResult> generateInitialGuestPlan({
    int days = 7,
    DateTime? startDate,
    String? requestId,
    GeneratedPlanProgressCallback? onProgress,
  }) async {
    aiService.resetTransientModelCooldowns();
    return _generatePlan(
      actorMode: GeneratedPlanActorModes.initialGuest,
      requestId: requestId,
      days: days,
      startDate: startDate,
      appendAfterExisting: false,
      markGuestInitialPlanUsed: true,
      routinePreferences: null,
      onProgress: onProgress,
    );
  }

  void _reportProgress(
    GeneratedPlanProgressCallback? onProgress,
    GeneratedPlanProgress progress,
  ) {
    if (onProgress == null) return;
    try {
      onProgress(progress);
    } catch (error) {
      AppLogger.warning(
        _tag,
        'Schedule progress update skipped; errorType=${error.runtimeType}',
      );
    }
  }

  int _previouslySavedDayCount(
    PersonalScheduleAiRequestRecord? request, {
    required String userId,
    required String actorMode,
    required int days,
  }) {
    if (request == null ||
        request.userId != userId ||
        request.actorMode != actorMode ||
        request.days != days ||
        request.isSucceeded ||
        request.mealCount % MealPlanAiNormalizer.mealsPerDay != 0 ||
        request.exerciseCount % ExerciseTasksAiNormalizer.exercisesPerDay !=
            0) {
      return 0;
    }
    final mealDays = request.mealCount ~/ MealPlanAiNormalizer.mealsPerDay;
    final exerciseDays =
        request.exerciseCount ~/ ExerciseTasksAiNormalizer.exercisesPerDay;
    if (mealDays != exerciseDays || mealDays < 0 || mealDays > days) {
      return 0;
    }
    return mealDays;
  }

  /// Reports whether an interrupted or failed initial guest plan can resume
  /// from its persisted request and staging data.
  Future<bool> hasRetryableInitialGuestPlan() async {
    final profile = await dailyHealthDatasource.fetchLatestProfile();
    if (await requestStore.isGuestInitialPlanUsed(profile.userId)) {
      return false;
    }

    final request = await requestStore.findByRequestId(
      _defaultRequestId(
        actorMode: GeneratedPlanActorModes.initialGuest,
        userId: profile.userId,
      ),
    );
    return request != null &&
        request.actorMode == GeneratedPlanActorModes.initialGuest &&
        request.days == 7 &&
        (request.status == GeneratedPlanRequestStatuses.failed ||
            request.status == GeneratedPlanRequestStatuses.generating);
  }

  Future<GeneratedPlanResult> _generatePlan({
    required String actorMode,
    required String? requestId,
    required int days,
    DateTime? startDate,
    required bool appendAfterExisting,
    required bool markGuestInitialPlanUsed,
    required DailyRoutinePreferences? routinePreferences,
    GeneratedPlanProgressCallback? onProgress,
  }) async {
    if (days < 1 || days > 7) {
      throw RangeError.range(days, 1, 7, 'days');
    }
    final generatedAt = now();
    final fallbackStartDate = _dateOnly(
      startDate ??
          LifestyleScheduleWindowPolicy.toVietnamWallClock(generatedAt),
    );
    AppLogger.action(_tag, 'Generate next plan');

    final profile = await dailyHealthDatasource.fetchLatestProfile();
    final userId = profile.userId;
    final resolvedRequestId = requestId == null || requestId.trim().isEmpty
        ? _defaultRequestId(actorMode: actorMode, userId: userId)
        : _normalizeRequestId(requestId);

    final existing = await _existingSucceededResult(
      resolvedRequestId,
      actorMode: actorMode,
    );
    if (existing != null) {
      _reportProgress(
        onProgress,
        GeneratedPlanProgress(
          totalDays: existing.days,
          savedDays: List<int>.generate(existing.days, (index) => index + 1),
        ),
      );
      return existing;
    }

    if (actorMode == GeneratedPlanActorModes.initialGuest &&
        await requestStore.isGuestInitialPlanUsed(userId)) {
      throw const GuestInitialPlanAlreadyUsedException();
    }

    final preferences =
        routinePreferences ??
        await routinePreferencesRepository.loadForUser(userId);
    if (preferences == null) {
      throw const DailyRoutinePreferencesRequiredException();
    }
    final DashboardEntity dashboardData = await dashboardRepository
        .fetchDashboard();
    final nutritionProfile = await nutritionProfileDatasource.load(userId);
    final exercisePreferences = await exercisePreferencesDatasource.loadForUser(
      userId,
    );

    final previousRequest = await requestStore.findByRequestId(
      resolvedRequestId,
    );
    final previouslySavedDays = _previouslySavedDayCount(
      previousRequest,
      userId: userId,
      actorMode: actorMode,
      days: days,
    );
    if (previouslySavedDays > 0) {
      _reportProgress(
        onProgress,
        GeneratedPlanProgress(
          totalDays: days,
          savedDays: List<int>.generate(
            previouslySavedDays,
            (index) => index + 1,
          ),
        ),
      );
    }
    final canResumeWithPreviousDate =
        startDate == null &&
        previousRequest != null &&
        previousRequest.userId == userId &&
        previousRequest.actorMode == actorMode &&
        previousRequest.days == days &&
        !previousRequest.isSucceeded &&
        previousRequest.startDate != null;
    final resolvedStartDate = canResumeWithPreviousDate
        ? _dateOnly(previousRequest.startDate!)
        : fallbackStartDate;

    await requestStore.markGenerating(
      requestId: resolvedRequestId,
      userId: userId,
      actorMode: actorMode,
      startDate: resolvedStartDate,
      days: days,
    );

    AppLogger.info(_tag, 'Resolved generated-plan range for $days days');

    var failureStage = 'load_catalog';
    try {
      final fullCatalog = await catalogDatasource.loadScheduleCatalogBundle();
      AppLogger.info(
        _tag,
        'Loaded full schedule catalog counts: '
        'meals=${fullCatalog.meals.length}, '
        'exercises=${fullCatalog.exercises.length}, '
        'selectableExercises=${fullCatalog.exercises.where((item) => item.isActive).length}',
      );

      final scheduleCatalog = fullCatalog;
      _ensureMealSlotsAvailable(scheduleCatalog);
      final mealPersonalization = ScheduleAiPersonalizationContext.forMeals(
        profile: profile,
        dashboard: dashboardData,
        nutritionProfile: nutritionProfile,
      );
      final exercisePersonalization =
          ScheduleAiPersonalizationContext.forExercise(
            profile: profile,
            preferences: exercisePreferences,
            nutritionProfile: nutritionProfile,
          );
      final fallbackMealCodesByType = {
        for (final slot in MealPlanAiNormalizer.mealSlots)
          slot.type: const MealCandidateSelector()
              .eligibleMeals(
                catalog: scheduleCatalog.meals,
                profile: nutritionProfile,
                mealType: slot.type,
                conditions: profile.conditions.toSet(),
                goals: profile.goals.toSet(),
                additionalAllergies: dashboardData.allergyName.trim().isEmpty
                    ? const {}
                    : {dashboardData.allergyName.trim()},
              )
              .map((meal) => meal.code)
              .toSet(),
      };
      final fallbackExerciseCodes = const ExerciseCandidateSelector()
          .eligibleExercises(
            catalog: scheduleCatalog.exercises,
            profile: profile,
            preferences: exercisePreferences,
          )
          .map((exercise) => exercise.code)
          .toSet();
      _printScheduleDiagnostic(
        'catalog_loaded',
        data: {
          'mealCount': scheduleCatalog.meals.length,
          'exerciseCount': scheduleCatalog.exercises.length,
          'selectableExerciseCount': scheduleCatalog.exercises
              .where((item) => item.isActive)
              .length,
        },
      );

      failureStage = 'prepare_staging';
      const promptVersion = 'personal_schedule_v8_weekly_meal_uniqueness';
      final inputFingerprint = _inputFingerprint(
        userId: userId,
        startDate: resolvedStartDate,
        days: days,
        profile: profile,
        dashboardData: dashboardData,
        nutritionProfile: nutritionProfile,
        exercisePreferences: exercisePreferences,
        routinePreferences: preferences,
      );
      final catalogFingerprint = _catalogFingerprint(scheduleCatalog);
      final staging = await requestStore.prepareStaging(
        requestId: resolvedRequestId,
        inputFingerprint: inputFingerprint,
        catalogFingerprint: catalogFingerprint,
        promptVersion: promptVersion,
      );
      final stagedChunks = staging.chunks;
      final stagedSources = Map<String, PlanGenerationSource>.of(
        staging.chunkSources,
      );
      var persistedMealCount = 0;
      var persistedExerciseCount = 0;
      var persistedScheduleItemCount = 0;

      Future<void> countBackendInvocation() async {
        final invocationCount = await requestStore
            .incrementBackendInvocationCount(
              requestId: resolvedRequestId,
              inputFingerprint: inputFingerprint,
              catalogFingerprint: catalogFingerprint,
              promptVersion: promptVersion,
            );
        _printScheduleDiagnostic(
          'backend_invocation',
          data: {'backendInvocationCount': invocationCount},
        );
      }

      for (var day = 1; day <= days; day++) {
        final mealKey = 'meal:$day';
        if (!stagedChunks.containsKey(mealKey)) {
          final mealUsedCounts = _usedCodeCounts(
            stagedChunks,
            prefix: 'meal:',
            beforeDay: day,
            codeKey: 'meal_code',
          );
          final slotKeys = {
            for (final slot in MealPlanAiNormalizer.mealSlots)
              'meal_slot:$day:${slot.type}',
          };
          final hasStagedMealSlots = stagedChunks.keys.any(slotKeys.contains);
          List<Map<String, dynamic>>? mealItems;
          PlanGenerationSource? mealSource;

          if (!hasStagedMealSlots) {
            failureStage = 'generate_meal_day_$day';
            _printScheduleDiagnostic(failureStage);
            AppLogger.info(_tag, 'Generating meal candidates for day $day');
            aiService.resetTransientModelCooldowns();
            try {
              final mealResult = await aiService
                  .generateMealDayCodeItemsWithSource(
                    startDate: resolvedStartDate,
                    day: day,
                    catalog: scheduleCatalog,
                    usedCodeCounts: mealUsedCounts,
                    eligibleFallbackCodesByType: fallbackMealCodesByType,
                    allowLocalFallback: false,
                    personalization: mealPersonalization,
                    onBackendInvocation: countBackendInvocation,
                  );
              mealItems = mealResult.value;
              mealSource = mealResult.source;
            } catch (error) {
              _printScheduleDiagnostic(
                'meal_day_escalate_to_slots',
                data: {'day': day, 'errorType': error.runtimeType.toString()},
              );
            }
          }

          if (mealItems == null) {
            failureStage = 'generate_meal_slots_$day';
            _printScheduleDiagnostic(failureStage);
            final slotItems = <Map<String, dynamic>>[];
            final slotSources = <PlanGenerationSource>[];
            final dayMealCodes = <String>{};
            final dayUsedCounts = Map<String, int>.of(mealUsedCounts);
            for (final slot in MealPlanAiNormalizer.mealSlots) {
              final slotKey = 'meal_slot:$day:${slot.type}';
              var slotPayload = stagedChunks[slotKey];
              var slotSource = stagedSources[slotKey];
              if (slotPayload == null) {
                failureStage = 'generate_meal_slot_${slot.type}_day_$day';
                _printScheduleDiagnostic(failureStage);
                aiService.resetTransientModelCooldowns();
                final slotResult = await aiService
                    .generateMealSlotCodeItemWithSource(
                      startDate: resolvedStartDate,
                      day: day,
                      mealType: slot.type,
                      catalog: scheduleCatalog,
                      usedCodeCounts: dayUsedCounts,
                      dayMealCodes: dayMealCodes,
                      eligibleFallbackCodesByType: fallbackMealCodesByType,
                      personalization: mealPersonalization,
                      onBackendInvocation: countBackendInvocation,
                    );
                slotPayload = slotResult.value;
                slotSource = slotResult.source;
                await requestStore.saveStagedChunk(
                  requestId: resolvedRequestId,
                  inputFingerprint: inputFingerprint,
                  catalogFingerprint: catalogFingerprint,
                  promptVersion: promptVersion,
                  chunkKey: slotKey,
                  payload: slotPayload,
                  source: slotSource,
                );
                stagedChunks[slotKey] = slotPayload;
                stagedSources[slotKey] = slotSource;
              }

              final validatedSlot = const MealPlanAiNormalizer()
                  .validateCodeItemForSlot(
                    item: slotPayload.single,
                    catalog: scheduleCatalog,
                    day: day,
                    mealType: slot.type,
                    usedCodeCounts: dayUsedCounts,
                    dayMealCodes: dayMealCodes,
                  );
              slotItems.addAll(validatedSlot);
              final mealCode = validatedSlot.single['meal_code']! as String;
              dayMealCodes.add(mealCode);
              dayUsedCounts.update(
                mealCode,
                (value) => value + 1,
                ifAbsent: () => 1,
              );
              slotSources.add(slotSource ?? PlanGenerationSource.unknown);
            }
            mealItems = const MealPlanAiNormalizer().validateCodeItems(
              items: slotItems,
              catalog: scheduleCatalog,
              startDay: day,
              days: 1,
              usedCodeCounts: mealUsedCounts,
            );
            mealSource = PlanGenerationSource.combine(slotSources);
          }

          final completedMealItems = mealItems;
          final completedMealSource = mealSource ?? PlanGenerationSource.ai;
          await requestStore.saveStagedChunk(
            requestId: resolvedRequestId,
            inputFingerprint: inputFingerprint,
            catalogFingerprint: catalogFingerprint,
            promptVersion: promptVersion,
            chunkKey: mealKey,
            payload: completedMealItems,
            source: completedMealSource,
          );
          stagedChunks[mealKey] = completedMealItems;
          stagedSources[mealKey] = completedMealSource;
        }

        final exerciseKey = 'exercise:$day';
        if (!stagedChunks.containsKey(exerciseKey)) {
          failureStage = 'generate_exercise_day_$day';
          _printScheduleDiagnostic(failureStage);
          AppLogger.info(_tag, 'Generating exercise candidates for day $day');
          aiService.resetTransientModelCooldowns();
          final exerciseResult = await aiService
              .generateExerciseDayCodeItemsWithSource(
                startDate: resolvedStartDate,
                day: day,
                catalog: scheduleCatalog,
                usedCodeCounts: _usedCodeCounts(
                  stagedChunks,
                  prefix: 'exercise:',
                  beforeDay: day,
                  codeKey: 'exercise_code',
                ),
                eligibleFallbackCodes: fallbackExerciseCodes,
                personalization: exercisePersonalization,
                onBackendInvocation: countBackendInvocation,
              );
          final exerciseItems = exerciseResult.value;
          await requestStore.saveStagedChunk(
            requestId: resolvedRequestId,
            inputFingerprint: inputFingerprint,
            catalogFingerprint: catalogFingerprint,
            promptVersion: promptVersion,
            chunkKey: exerciseKey,
            payload: exerciseItems,
            source: exerciseResult.source,
          );
          stagedChunks[exerciseKey] = exerciseItems;
          stagedSources[exerciseKey] = exerciseResult.source;
        }

        final dayDate = resolvedStartDate.add(Duration(days: day - 1));
        final dayMeals = const MealPlanAiNormalizer()
            .normalize(
              items: _rebaseChunkToDayOne(stagedChunks[mealKey]!),
              catalog: scheduleCatalog,
              userId: userId,
              startDate: dayDate,
              days: 1,
              createdAt: now().toIso8601String(),
            )
            .map((meal) {
              final range = timingResolver
                  .resolve(preferences, dayDate)
                  .mealRange(meal.mealOrder);
              return meal.copyWith(startTime: range.start, endTime: range.end);
            })
            .toList(growable: false);
        final dayExercises = const ExerciseTasksAiNormalizer()
            .normalize(
              items: _rebaseChunkToDayOne(stagedChunks[exerciseKey]!),
              profile: profile,
              catalog: scheduleCatalog,
              startDate: dayDate,
              days: 1,
              createdAt: now().toIso8601String(),
            )
            .toList(growable: false);
        final dayExerciseIndexByDate = <String, int>{};
        final timedDayExercises = dayExercises
            .map((exercise) {
              final index = dayExerciseIndexByDate.update(
                exercise.scheduleDate,
                (value) => value + 1,
                ifAbsent: () => 0,
              );
              final range = timingResolver
                  .resolve(preferences, dayDate)
                  .workoutRange(index);
              return exercise.copyWith(
                startTime: range.start,
                endTime: range.end,
              );
            })
            .toList(growable: false);
        final daySchedule = const LifestyleScheduleTimelineBuilder().generate(
          profile: profile,
          meals: dayMeals,
          exercises: timedDayExercises,
          catalog: scheduleCatalog,
          startDate: dayDate,
          days: 1,
          createdAt: now().toIso8601String(),
          routinePreferences: preferences,
          timingResolver: timingResolver,
        );
        scheduleDatasource.validateGeneratedSchedule(
          daySchedule,
          startDate: dayDate,
          days: 1,
        );
        persistedMealCount += dayMeals.length;
        persistedExerciseCount += timedDayExercises.length;
        persistedScheduleItemCount += daySchedule.length;
        final daySource = PlanGenerationSource.combine([
          for (var sourceDay = 1; sourceDay <= day; sourceDay++) ...[
            stagedSources['meal:$sourceDay'] ?? PlanGenerationSource.unknown,
            stagedSources['exercise:$sourceDay'] ??
                PlanGenerationSource.unknown,
          ],
        ]);
        await requestStore.saveGeneratedPlanDay(
          requestId: resolvedRequestId,
          userId: userId,
          actorMode: actorMode,
          startDate: resolvedStartDate,
          days: days,
          day: day,
          meals: dayMeals,
          schedule: daySchedule,
          replaceExistingDay: !appendAfterExisting,
          mealCount: persistedMealCount,
          exerciseCount: persistedExerciseCount,
          scheduleItemCount: persistedScheduleItemCount,
          generationSource: daySource,
        );
        _reportProgress(
          onProgress,
          GeneratedPlanProgress(
            totalDays: days,
            savedDays: List<int>.generate(day, (index) => index + 1),
          ),
        );
        _printScheduleDiagnostic(
          'day_committed',
          data: {
            'mealCount': persistedMealCount,
            'exerciseCount': persistedExerciseCount,
            'scheduleItemCount': persistedScheduleItemCount,
          },
        );
      }

      final mealCodeItems = [
        for (var day = 1; day <= days; day++) ...stagedChunks['meal:$day']!,
      ];
      final exerciseCodeItems = [
        for (var day = 1; day <= days; day++) ...stagedChunks['exercise:$day']!,
      ];
      final createdAt = now().toIso8601String();
      failureStage = 'normalize_meals';
      final meals = const MealPlanAiNormalizer()
          .normalize(
            items: mealCodeItems,
            catalog: scheduleCatalog,
            userId: userId,
            startDate: resolvedStartDate,
            days: days,
            createdAt: createdAt,
          )
          .map((meal) {
            final date = _requiredDate(meal.planDate);
            final range = timingResolver
                .resolve(preferences, date)
                .mealRange(meal.mealOrder);
            return meal.copyWith(startTime: range.start, endTime: range.end);
          })
          .toList(growable: false);
      AppLogger.info(_tag, 'Generated ${meals.length} meal records');

      failureStage = 'normalize_exercises';
      final exercises = const ExerciseTasksAiNormalizer()
          .normalize(
            items: exerciseCodeItems,
            profile: profile,
            catalog: scheduleCatalog,
            startDate: resolvedStartDate,
            days: days,
            createdAt: createdAt,
          )
          .toList(growable: false);
      final exerciseIndexByDate = <String, int>{};
      final timedExercises = exercises
          .map((exercise) {
            final index = exerciseIndexByDate.update(
              exercise.scheduleDate,
              (value) => value + 1,
              ifAbsent: () => 0,
            );
            final range = timingResolver
                .resolve(preferences, _requiredDate(exercise.scheduleDate))
                .workoutRange(index);
            return exercise.copyWith(
              startTime: range.start,
              endTime: range.end,
            );
          })
          .toList(growable: false);
      AppLogger.info(
        _tag,
        'Generated ${timedExercises.length} exercise records',
      );

      failureStage = 'build_schedule';
      final catalog = scheduleCatalog;
      final schedule = const LifestyleScheduleTimelineBuilder().generate(
        profile: profile,
        meals: meals,
        exercises: timedExercises,
        catalog: catalog,
        startDate: resolvedStartDate,
        days: days,
        createdAt: createdAt,
        routinePreferences: preferences,
        timingResolver: timingResolver,
      );
      failureStage = 'validate_schedule';
      scheduleDatasource.validateGeneratedSchedule(
        schedule,
        startDate: resolvedStartDate,
        days: days,
      );
      final generationSource = PlanGenerationSource.combine([
        for (var day = 1; day <= days; day++) ...[
          stagedSources['meal:$day'] ?? PlanGenerationSource.unknown,
          stagedSources['exercise:$day'] ?? PlanGenerationSource.unknown,
        ],
      ]);

      failureStage = 'commit_plan';
      await requestStore.commitGeneratedPlan(
        requestId: resolvedRequestId,
        userId: userId,
        actorMode: actorMode,
        startDate: resolvedStartDate,
        days: days,
        meals: meals,
        schedule: schedule,
        generationSource: generationSource,
        markGuestInitialPlanUsed: markGuestInitialPlanUsed,
      );
      _printScheduleDiagnostic(
        'plan_committed',
        data: {
          'mealCount': meals.length,
          'exerciseCount': timedExercises.length,
          'scheduleItemCount': schedule.length,
        },
      );
      AppLogger.info(_tag, 'Saved ${schedule.length} schedule items');

      try {
        await scheduleReminders();
        AppLogger.success(_tag, 'Scheduled generated reminders');
      } catch (error) {
        AppLogger.warning(
          _tag,
          'Failed to schedule generated reminders; '
          'errorType=${error.runtimeType}',
        );
      }

      return GeneratedPlanResult(
        requestId: resolvedRequestId,
        startDate: resolvedStartDate,
        days: days,
        mealCount: meals.length,
        exerciseCount: timedExercises.length,
        scheduleItemCount: schedule.length,
        generationSource: generationSource,
        rewardEligibilityItems: actorMode == GeneratedPlanActorModes.memberNew
            ? schedule
                  .map(
                    (item) => ScheduleRewardEligibilityItem(
                      scheduleItemId: item.id,
                      scheduleDate: item.scheduleDate,
                      startTime: item.startTime,
                      title: item.title,
                      sourceType: item.sourceType,
                      sourceId: item.sourceId,
                    ),
                  )
                  .toList(growable: false)
            : const [],
      );
    } catch (error, stackTrace) {
      _printScheduleDiagnostic(
        failureStage,
        data: {
          'errorType': error.runtimeType.toString(),
          'errorCode': _errorCode(error),
        },
        stackTrace: stackTrace,
      );
      AppLogger.error(
        _tag,
        'Plan generation failed at stage=$failureStage '
        'errorCode=${_errorCode(error)}',
        error,
        stackTrace,
      );
      await _markFailedSafely(
        requestId: resolvedRequestId,
        userId: userId,
        actorMode: actorMode,
        startDate: resolvedStartDate,
        days: days,
        errorCode: _errorCode(error),
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void _ensureMealSlotsAvailable(AiCatalogBundle catalog) {
    for (final slot in MealPlanAiNormalizer.mealSlots) {
      final hasActiveCandidate = catalog
          .mealsForType(slot.type)
          .any(
            (meal) =>
                meal.isActive &&
                meal.code.trim().isNotEmpty &&
                meal.mealName.trim().isNotEmpty,
          );
      if (!hasActiveCandidate) {
        throw StateError(
          'No active local meal candidate remains for ${slot.type}.',
        );
      }
    }
  }

  Map<String, int> _usedCodeCounts(
    Map<String, List<Map<String, dynamic>>> chunks, {
    required String prefix,
    required int beforeDay,
    required String codeKey,
  }) {
    final counts = <String, int>{};
    for (final entry in chunks.entries) {
      if (!entry.key.startsWith(prefix)) continue;
      final day = int.tryParse(entry.key.substring(prefix.length));
      if (day == null || day >= beforeDay) continue;
      for (final item in entry.value) {
        final code = item[codeKey]?.toString().trim();
        if (code == null || code.isEmpty) continue;
        counts.update(code, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    return counts;
  }

  List<Map<String, dynamic>> _rebaseChunkToDayOne(
    List<Map<String, dynamic>> items,
  ) => [
    for (final item in items) {...item, 'day': 1},
  ];

  String _inputFingerprint({
    required String userId,
    required DateTime startDate,
    required int days,
    required DailyHealthProfileEntity profile,
    required DashboardEntity dashboardData,
    required NutritionProfileEntity nutritionProfile,
    required ExercisePlanningPreferences exercisePreferences,
    required DailyRoutinePreferences routinePreferences,
  }) {
    final conditions = [...profile.conditions]..sort();
    final goals = <String>{
      ...profile.goals,
      ...nutritionProfile.goals
          .where((item) => item.isActive)
          .map((item) => '${item.code}:${item.name}'),
    }.toList()..sort();
    final restrictions =
        nutritionProfile.restrictions
            .where((item) => item.isActive)
            .map((item) => '${item.type}:${item.itemName}')
            .toList()
          ..sort();
    final preferences =
        nutritionProfile.preferenceRules
            .where((item) => item.isActive)
            .map((item) => '${item.preferenceLevel}:${item.itemName}')
            .toList()
          ..sort();
    final equipment = [...exercisePreferences.availableEquipment]..sort();
    final limitations = [...exercisePreferences.mobilityLimitations]..sort();
    return _fingerprint({
      'user': userId,
      'start_date': _dateKey(startDate),
      'days': days,
      'conditions': conditions,
      'goals': goals,
      'allergy_name': dashboardData.allergyName.trim().toLowerCase(),
      'unparsed_allergy_note': _hasUnparsedAllergyNote(
        dashboardData.allergyNote,
      ),
      'food_restrictions': restrictions,
      'meal_preferences': preferences,
      'exercise_equipment': equipment,
      'mobility_limitations': limitations,
      'routine': routinePreferences.toJson(),
    });
  }

  String _catalogFingerprint(AiCatalogBundle catalog) {
    final meals = [...catalog.meals]
      ..sort((left, right) => left.code.compareTo(right.code));
    final exercises = [...catalog.exercises]
      ..sort((left, right) => left.code.compareTo(right.code));
    final evidence = catalog.ingredientEvidenceByName.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return _fingerprint({
      'meals': meals.map((item) => item.toMap()).toList(growable: false),
      'exercises': exercises
          .map((item) => item.toMap())
          .toList(growable: false),
      'ingredient_evidence': evidence
          .map((entry) => entry.value.toMap())
          .toList(growable: false),
    });
  }

  String _fingerprint(Object value) =>
      sha256.convert(utf8.encode(jsonEncode(value))).toString();

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  bool _hasUnparsedAllergyNote(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return !const {
      'không',
      'không có',
      'không dị ứng',
      'không có dị ứng',
      'none',
      'no',
      'no allergies',
    }.contains(normalized);
  }

  Future<GeneratedPlanResult?> _existingSucceededResult(
    String requestId, {
    required String actorMode,
  }) async {
    final existing = await requestStore.findByRequestId(requestId);
    if (existing == null ||
        existing.actorMode != actorMode ||
        !existing.isSucceeded ||
        existing.startDate == null) {
      return null;
    }

    AppLogger.info(
      _tag,
      'Reusing generated plan request ref=${_maskedRequestId(requestId)}',
    );
    return GeneratedPlanResult(
      requestId: requestId,
      startDate: existing.startDate!,
      days: existing.days,
      mealCount: existing.mealCount,
      exerciseCount: existing.exerciseCount,
      scheduleItemCount: existing.scheduleItemCount,
      reusedExistingRequest: true,
      generationSource: existing.generationSource,
    );
  }

  Future<void> _markFailedSafely({
    required String requestId,
    required String userId,
    required String actorMode,
    required DateTime startDate,
    required int days,
    required String errorCode,
  }) async {
    try {
      await requestStore.markFailed(
        requestId: requestId,
        userId: userId,
        actorMode: actorMode,
        startDate: startDate,
        days: days,
        errorCode: errorCode,
      );
    } catch (error) {
      AppLogger.warning(
        _tag,
        'Failed to record generated plan request failure; '
        'errorType=${error.runtimeType}',
      );
    }
  }

  String _normalizeRequestId(String requestId) {
    final normalized = requestId.trim();
    if (normalized.isEmpty) {
      throw StateError('Generated plan request id is required');
    }
    return normalized;
  }

  String _maskedRequestId(String requestId) {
    var hash = 0x811c9dc5;
    for (final codeUnit in requestId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  String _defaultRequestId({
    required String actorMode,
    required String userId,
  }) {
    if (actorMode == GeneratedPlanActorModes.initialGuest) {
      return 'guest_initial_plan:$userId';
    }
    return 'member_plan:$userId:${now().toUtc().microsecondsSinceEpoch}';
  }

  String _errorCode(Object error) {
    if (error is ScheduleCandidatesUnavailableException) {
      return 'schedule_candidates_unavailable';
    }
    if (error is AIRateLimitedException) return 'ai_rate_limited';
    if (error is PersonalScheduleAiInvocationLimitException) {
      return 'ai_invocation_limit';
    }
    if (error is AIConfigurationUnavailableException) {
      return 'ai_configuration_unavailable';
    }
    if (error is AIAuthenticationException) return 'ai_authentication_failed';
    if (AIModelContextLimitException.matches(error)) {
      return 'ai_model_context_limit';
    }
    if (AIRequestTooLargeException.matches(error)) {
      return 'ai_request_too_large';
    }
    if (error is AIOverloadedException) return 'ai_overloaded';
    if (error is AIResponseInvalidException) return 'ai_response_invalid';
    if (error is FormatException) {
      return _formatGenerationErrorCode(error.message.toString());
    }
    if (error is StateError) {
      final message = error.message.toString();
      if (message.contains('staging fingerprint changed')) {
        return 'staging_fingerprint_changed';
      }
      if (message.contains('staging data')) return 'staging_data_invalid';
      if (message.contains('unique eligible meal catalog choices') ||
          message.contains('Insufficient eligible meal choices')) {
        return 'meal_unique_candidates_unavailable';
      }
      return 'invalid_generation';
    }
    return 'generation_failed';
  }

  String _formatGenerationErrorCode(String message) {
    final normalized = message.trim();
    if (normalized.startsWith('Meal AI response must contain exactly')) {
      return 'meal_item_count_invalid';
    }
    if (normalized == 'Meal AI item must be an object') {
      return 'meal_item_not_object';
    }
    if (normalized.startsWith('Meal AI item must not contain')) {
      return 'meal_output_field_forbidden';
    }
    if (normalized.startsWith('Meal AI item must contain only')) {
      return 'meal_output_keys_invalid';
    }
    if (normalized.startsWith('Meal AI day must be between')) {
      return 'meal_day_out_of_range';
    }
    if (normalized.startsWith('Unsupported meal_type')) {
      return 'meal_type_unsupported';
    }
    if (normalized.startsWith('Unknown meal_code')) {
      return 'meal_code_unknown';
    }
    if (normalized.startsWith('Inactive meal_code')) {
      return 'meal_code_inactive';
    }
    if (normalized.startsWith('Meal catalog name is empty')) {
      return 'meal_catalog_name_missing';
    }
    if (normalized.startsWith('meal_code ') &&
        normalized.contains(' is not valid for ')) {
      return 'meal_code_type_mismatch';
    }
    if (normalized.startsWith('Duplicate meal_type for day')) {
      return 'meal_day_duplicate_type';
    }
    if (normalized.startsWith('Duplicate meal_code for day')) {
      return 'meal_day_duplicate_code';
    }
    if (normalized == 'Duplicate meal_code across the week.') {
      return 'meal_week_duplicate_code';
    }
    if (normalized == 'Duplicate meal_name across the week.') {
      return 'meal_week_duplicate_name';
    }
    if (normalized.startsWith('Missing meal day')) {
      return 'meal_day_missing';
    }
    if (normalized.startsWith('Expected meal_type')) {
      return 'meal_day_incomplete';
    }
    if (normalized.startsWith('Expected integer value')) {
      return 'meal_day_not_integer';
    }
    if (normalized.startsWith('Exercise AI response must contain exactly')) {
      return 'exercise_item_count_invalid';
    }
    if (normalized.startsWith('Exercise AI task must be an object')) {
      return 'exercise_item_not_object';
    }
    if (normalized.startsWith('Exercise AI item must not contain')) {
      return 'exercise_output_field_forbidden';
    }
    if (normalized.startsWith('Exercise AI item must contain only')) {
      return 'exercise_output_keys_invalid';
    }
    if (normalized.startsWith('Exercise AI day must be between')) {
      return 'exercise_day_out_of_range';
    }
    if (normalized.startsWith('Unknown exercise_code')) {
      return 'exercise_code_unknown';
    }
    if (normalized.startsWith('Inactive exercise_code')) {
      return 'exercise_code_inactive';
    }
    if (normalized.startsWith('Duplicate exercise_code for day')) {
      return 'exercise_day_duplicate_code';
    }
    if (normalized.startsWith('Exercise code repeated too often')) {
      return 'exercise_code_reuse_limit';
    }
    if (normalized.startsWith('Expected 2 exercises for day')) {
      return 'exercise_day_incomplete';
    }
    if (normalized.startsWith('Expected integer value')) {
      return 'exercise_day_not_integer';
    }
    return 'invalid_generation';
  }

  void _printScheduleDiagnostic(
    String stage, {
    Map<String, Object?> data = const {},
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;
    const allowedKeys = {
      'mealCount',
      'exerciseCount',
      'selectableExerciseCount',
      'scheduleItemCount',
      'backendInvocationCount',
      'errorCode',
      'errorType',
    };
    final safeData = <String, Object?>{
      for (final entry in data.entries)
        if (allowedKeys.contains(entry.key)) entry.key: entry.value,
    };
    // ignore: avoid_print
    print(
      '[NABI_AI_SCHEDULE] ${jsonEncode({'component': 'GENERATED_PLAN', 'stage': stage, ...safeData})}',
    );
    if (stackTrace == null) return;
    for (final line in stackTrace.toString().split('\n').take(12)) {
      if (line.trim().isEmpty) continue;
      // ignore: avoid_print
      print('[NABI_AI_SCHEDULE] stack=$line');
    }
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _requiredDate(String value) {
    final parsed = DateTime.tryParse(value.trim());
    if (parsed == null) throw const FormatException('Invalid schedule date');
    return _dateOnly(parsed);
  }
}
