import 'package:nano_app/core/storage/localdb/datasources/ai_catalog_local_datasource.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:nano_app/app_versions/v1/features/daily_health_tracking/data/datasources/daily_health_tracking_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/datasources/lifestyle_schedule_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/data/models/lifestyle_schedule_timeline_builder.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_service.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_bootstrap.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

class DashboardGenerationAuthRequiredException implements Exception {
  static const userMessage =
      'Bạn cần đăng nhập để Nami tạo dữ liệu lịch trình 7 ngày mới nhé.';

  const DashboardGenerationAuthRequiredException();

  @override
  String toString() => userMessage;
}

void requireAuthenticatedGeneratedPlanUser(String? userId) {
  if (userId == null || userId.trim().isEmpty) {
    throw const DashboardGenerationAuthRequiredException();
  }
}

class GeneratedPlanResult {
  final DateTime startDate;
  final int days;
  final int mealCount;
  final int exerciseCount;
  final int scheduleItemCount;

  const GeneratedPlanResult({
    required this.startDate,
    required this.days,
    required this.mealCount,
    required this.exerciseCount,
    required this.scheduleItemCount,
  });
}

class GeneratedPlanService {
  static const _tag = 'GENERATED_PLAN';

  final DashboardRepository dashboardRepository;
  final DailyHealthTrackingLocalDatasource dailyHealthDatasource;
  final LifestyleScheduleLocalDatasource scheduleDatasource;
  final AIService aiService;
  final AiCatalogLocalDatasource catalogDatasource;
  final Future<void> Function() scheduleReminders;
  final String? Function() currentUserId;

  GeneratedPlanService({
    required this.dashboardRepository,
    required this.dailyHealthDatasource,
    required this.scheduleDatasource,
    required this.aiService,
    this.catalogDatasource = const AiCatalogLocalDatasource(),
    Future<void> Function()? scheduleReminders,
    String? Function()? currentUserId,
  }) : scheduleReminders =
           scheduleReminders ??
           NotificationBootstrap.scheduleGeneratedReminders,
       currentUserId = currentUserId ?? currentSupabaseUserIdOrNull;

  Future<GeneratedPlanResult> generateNextPlan({
    int days = 7,
    DateTime? startDate,
    bool appendAfterExisting = true,
  }) async {
    requireAuthenticatedGeneratedPlanUser(currentUserId());

    return _generatePlan(
      days: days,
      startDate: startDate,
      appendAfterExisting: appendAfterExisting,
    );
  }

  Future<GeneratedPlanResult> generateInitialGuestPlan({
    int days = 7,
    DateTime? startDate,
  }) async {
    return _generatePlan(
      days: days,
      startDate: startDate,
      appendAfterExisting: false,
    );
  }

  Future<GeneratedPlanResult> _generatePlan({
    required int days,
    DateTime? startDate,
    required bool appendAfterExisting,
  }) async {
    final now = DateTime.now();
    final fallbackStartDate = _dateOnly(
      startDate ?? DateTime(now.year, now.month, now.day + 1),
    );
    AppLogger.action(_tag, 'Generate next plan');

    final DashboardEntity dashboardData = await dashboardRepository
        .fetchDashboard();
    final profile = await dailyHealthDatasource.fetchLatestProfile();
    final resolvedStartDate = appendAfterExisting
        ? await scheduleDatasource.getNextGeneratedPlanStartDate(
            userId: profile.userId,
            fallbackStartDate: fallbackStartDate,
          )
        : fallbackStartDate;

    AppLogger.info(
      _tag,
      'Resolved start date ${_dateKey(resolvedStartDate)} for $days days',
    );

    final meals = await aiService.generateMealPlan(
      healthData: dashboardData,
      userId: profile.userId,
      startDate: resolvedStartDate,
      days: days,
    );
    await dashboardRepository.saveMealPlan(meals);
    AppLogger.info(_tag, 'Saved ${meals.length} meal records');

    final exercises = await aiService.generateExerciseTasks(
      profile: profile,
      startDate: resolvedStartDate,
      days: days,
    );
    AppLogger.info(_tag, 'Generated ${exercises.length} exercise records');

    final catalog = await catalogDatasource.loadActiveBundle();
    final mealsForSchedule = await scheduleDatasource
        .getMealPlansForScheduleSeed(
          userId: profile.userId,
          startDate: resolvedStartDate,
          days: days,
        );
    final createdAt = DateTime.now().toIso8601String();
    final schedule = const LifestyleScheduleTimelineBuilder().generate(
      profile: profile,
      meals: mealsForSchedule,
      exercises: exercises,
      catalog: catalog,
      startDate: resolvedStartDate,
      days: days,
      createdAt: createdAt,
    );
    await scheduleDatasource.seedGeneratedSchedule(
      schedule,
      requireComplete: true,
      replaceExistingRange: !appendAfterExisting,
      startDate: resolvedStartDate,
      days: days,
    );
    AppLogger.info(_tag, 'Saved ${schedule.length} schedule items');

    try {
      await scheduleReminders();
      AppLogger.success(_tag, 'Scheduled generated reminders');
    } catch (error, stackTrace) {
      AppLogger.error(
        _tag,
        'Failed to schedule generated reminders',
        error,
        stackTrace,
      );
    }

    return GeneratedPlanResult(
      startDate: resolvedStartDate,
      days: days,
      mealCount: meals.length,
      exerciseCount: exercises.length,
      scheduleItemCount: schedule.length,
    );
  }

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
