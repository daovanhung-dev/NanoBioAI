import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/utils/logger/app_logger.dart';
import 'features/daily_health_tracking/providers/daily_health_tracking_provider.dart';
import 'features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'features/lifestyle_schedule/data/models/lifestyle_schedule_timeline_builder.dart';
import 'features/lifestyle_schedule/providers/lifestyle_schedule_provider.dart';
import 'features/onboarding/providers/onboarding_completion_provider.dart';
import 'services/ai/ai_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // LOAD ENV
  await dotenv.load(fileName: ".env");

  // INIT SUPABASE
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

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
          };
        }),
      ],
      child: const BioAIApp(),
    ),
  );
}
