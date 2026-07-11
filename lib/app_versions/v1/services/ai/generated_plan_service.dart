import 'package:nano_app/core/storage/localdb/datasources/ai_catalog_local_datasource.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/data/datasources/daily_health_tracking_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/datasources/lifestyle_schedule_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/lifestyle_schedule_timeline_builder.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_exceptions.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_service.dart';
import 'package:nano_app/app_versions/v1/services/ai/generated_plan_request_store.dart';
import 'package:nano_app/app_versions/v1/services/ai/personal_schedule_quota_gateway.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_bootstrap.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

class DashboardGenerationAuthRequiredException implements Exception {
  static const userMessage =
      'Bạn cần đăng nhập để Nabitạo dữ liệu lịch trình 7 ngày mới nhé.';

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

class GeneratedPlanResult {
  final String requestId;
  final DateTime startDate;
  final int days;
  final int mealCount;
  final int exerciseCount;
  final int scheduleItemCount;
  final bool reusedExistingRequest;

  const GeneratedPlanResult({
    this.requestId = '',
    required this.startDate,
    required this.days,
    required this.mealCount,
    required this.exerciseCount,
    required this.scheduleItemCount,
    this.reusedExistingRequest = false,
  });
}

class GeneratedPlanService {
  static const _tag = 'GENERATED_PLAN';

  final DashboardRepository dashboardRepository;
  final DailyHealthTrackingLocalDatasource dailyHealthDatasource;
  final LifestyleScheduleLocalDatasource scheduleDatasource;
  final AIService aiService;
  final AiCatalogLocalDatasource catalogDatasource;
  final PersonalScheduleAiRequestStore requestStore;
  final PersonalScheduleQuotaGateway quotaGateway;
  final Future<void> Function() scheduleReminders;
  final String? Function() currentUserId;
  final DateTime Function() now;

  GeneratedPlanService({
    required this.dashboardRepository,
    required this.dailyHealthDatasource,
    required this.scheduleDatasource,
    required this.aiService,
    this.catalogDatasource = const AiCatalogLocalDatasource(),
    PersonalScheduleAiRequestStore? requestStore,
    PersonalScheduleQuotaGateway? quotaGateway,
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

    final decision = await quotaGateway.checkGeneration(
      userId: authUserId!,
      requestId: normalizedRequestId,
      at: now(),
    );
    if (!decision.allowed) {
      throw PersonalScheduleQuotaExceededException(resetAt: decision.resetAt);
    }

    final result = await _generatePlan(
      actorMode: GeneratedPlanActorModes.memberNew,
      requestId: normalizedRequestId,
      days: days,
      startDate: startDate,
      appendAfterExisting: appendAfterExisting,
      markGuestInitialPlanUsed: false,
    );

    await quotaGateway.commitGeneration(
      userId: authUserId,
      requestId: normalizedRequestId,
      at: now(),
    );

    return result;
  }

  Future<GeneratedPlanResult> generateInitialGuestPlan({
    int days = 7,
    DateTime? startDate,
    String? requestId,
  }) async {
    return _generatePlan(
      actorMode: GeneratedPlanActorModes.initialGuest,
      requestId: requestId,
      days: days,
      startDate: startDate,
      appendAfterExisting: false,
      markGuestInitialPlanUsed: true,
    );
  }

  Future<GeneratedPlanResult> _generatePlan({
    required String actorMode,
    required String? requestId,
    required int days,
    DateTime? startDate,
    required bool appendAfterExisting,
    required bool markGuestInitialPlanUsed,
  }) async {
    final generatedAt = now();
    final fallbackStartDate = _dateOnly(
      startDate ??
          DateTime(generatedAt.year, generatedAt.month, generatedAt.day + 1),
    );
    AppLogger.action(_tag, 'Generate next plan');

    final DashboardEntity dashboardData = await dashboardRepository
        .fetchDashboard();
    final profile = await dailyHealthDatasource.fetchLatestProfile();
    final userId = profile.userId;
    final resolvedRequestId = requestId == null || requestId.trim().isEmpty
        ? _defaultRequestId(actorMode: actorMode, userId: userId)
        : _normalizeRequestId(requestId);

    final existing = await _existingSucceededResult(
      resolvedRequestId,
      actorMode: actorMode,
    );
    if (existing != null) return existing;

    if (actorMode == GeneratedPlanActorModes.initialGuest &&
        await requestStore.isGuestInitialPlanUsed(userId)) {
      throw const GuestInitialPlanAlreadyUsedException();
    }

    final resolvedStartDate = appendAfterExisting
        ? await scheduleDatasource.getNextGeneratedPlanStartDate(
            userId: userId,
            fallbackStartDate: fallbackStartDate,
          )
        : fallbackStartDate;

    await requestStore.markGenerating(
      requestId: resolvedRequestId,
      userId: userId,
      actorMode: actorMode,
      startDate: resolvedStartDate,
      days: days,
    );

    AppLogger.info(_tag, 'Resolved generated-plan range for $days days');

    try {
      final meals = await aiService.generateMealPlan(
        healthData: dashboardData,
        userId: userId,
        startDate: resolvedStartDate,
        days: days,
      );
      AppLogger.info(_tag, 'Generated ${meals.length} meal records');

      final exercises = await aiService.generateExerciseTasks(
        profile: profile,
        startDate: resolvedStartDate,
        days: days,
      );
      AppLogger.info(_tag, 'Generated ${exercises.length} exercise records');

      final catalog = await catalogDatasource.loadActiveBundle();
      final createdAt = now().toIso8601String();
      final schedule = const LifestyleScheduleTimelineBuilder().generate(
        profile: profile,
        meals: meals,
        exercises: exercises,
        catalog: catalog,
        startDate: resolvedStartDate,
        days: days,
        createdAt: createdAt,
      );
      scheduleDatasource.validateGeneratedSchedule(
        schedule,
        startDate: resolvedStartDate,
        days: days,
      );

      await requestStore.commitGeneratedPlan(
        requestId: resolvedRequestId,
        userId: userId,
        actorMode: actorMode,
        startDate: resolvedStartDate,
        days: days,
        meals: meals,
        schedule: schedule,
        replaceExistingRange: !appendAfterExisting,
        markGuestInitialPlanUsed: markGuestInitialPlanUsed,
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
        exerciseCount: exercises.length,
        scheduleItemCount: schedule.length,
      );
    } catch (error) {
      await _markFailedSafely(
        requestId: resolvedRequestId,
        userId: userId,
        actorMode: actorMode,
        startDate: resolvedStartDate,
        days: days,
        errorCode: _errorCode(error),
      );
      rethrow;
    }
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
    if (error is AIOverloadedException) return 'ai_overloaded';
    if (error is FormatException || error is StateError) {
      return 'invalid_generation';
    }
    return 'generation_failed';
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
