import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/storage/localdb/app_prefs.dart';
import 'core/storage/localdb/datasources/ai_catalog_local_datasource.dart';
import 'core/utils/logger/app_logger.dart';
import 'features/daily_health_tracking/providers/daily_health_tracking_provider.dart';
import 'features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'features/lifestyle_schedule/data/models/lifestyle_schedule_timeline_builder.dart';
import 'features/lifestyle_schedule/providers/lifestyle_schedule_provider.dart';
import 'features/onboarding/providers/onboarding_completion_provider.dart';
import 'services/ai/ai_service.dart';
import 'services/notifications/notification_bootstrap.dart';
import 'services/notifications/notification_lifecycle_refresher.dart';
import 'services/notifications/notification_startup_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // LOAD ENV
  await dotenv.load(fileName: ".env");

  // INIT SUPABASE
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // INIT LOCAL NOTIFICATIONS
  await NotificationBootstrap.initialize();
  NotificationLifecycleRefresher(
    startupScheduler: NotificationStartupScheduler(
      isOnboardingCompleted: AppPrefs.isOnboardingCompleted,
      scheduleGeneratedReminders:
          NotificationBootstrap.scheduleGeneratedReminders,
    ),
  ).start();

  runApp(
    ProviderScope(
      overrides: [
        onboardingCompletionCallbackProvider.overrideWith((ref) {
          return () async {
            const tag = 'ONBOARDING_SCHEDULE';
            const days = 7;
            final now = DateTime.now();
            final startDate = DateTime(now.year, now.month, now.day + 1);

            await ref
                .read(dashboardControllerProvider.notifier)
                .genMealByWeeksToDB(
                  requireComplete: true,
                  startDate: startDate,
                  days: days,
                );

            final dailyDatasource = ref.read(
              dailyHealthTrackingLocalDatasourceProvider,
            );
            final profile = await dailyDatasource.fetchLatestProfile();
            final aiService = ref.read(aiServiceProvider);
            AppLogger.info(tag, 'Generating exercise tasks');
            final exercises = await aiService.generateExerciseTasks(
              profile: profile,
              startDate: startDate,
              days: days,
            );
            AppLogger.info(
              tag,
              'Generated ${exercises.length} exercise task records',
            );

            final scheduleDatasource = ref.read(
              lifestyleScheduleLocalDatasourceProvider,
            );
            final catalog = await const AiCatalogLocalDatasource()
                .loadActiveBundle();
            final meals = await scheduleDatasource.getMealPlansForScheduleSeed(
              userId: profile.userId,
              startDate: startDate,
              days: days,
            );
            AppLogger.info(
              tag,
              'Fetched ${meals.length} meal records for schedule seed',
            );
            final schedule = const LifestyleScheduleTimelineBuilder().generate(
              profile: profile,
              meals: meals,
              exercises: exercises,
              catalog: catalog,
              startDate: startDate,
              days: days,
              createdAt: DateTime.now().toIso8601String(),
            );
            AppLogger.info(
              tag,
              'Generated ${schedule.length} lifestyle schedule items',
            );
            await scheduleDatasource.seedGeneratedSchedule(
              schedule,
              requireComplete: true,
              startDate: startDate,
              days: days,
            );

            try {
              await NotificationBootstrap.scheduleGeneratedReminders();
              AppLogger.success(tag, 'Scheduled local reminder notifications');
            } catch (error, stackTrace) {
              AppLogger.error(
                tag,
                'Failed to schedule reminder notifications. Onboarding data remains completed.',
                error,
                stackTrace,
              );
            }
          };
        }),
      ],
      child: const BioAIApp(),
    ),
  );
}
