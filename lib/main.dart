import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'features/daily_health_tracking/providers/daily_health_tracking_provider.dart';
import 'features/dashboard/presentation/controllers/dashboard_controller.dart';
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
            await ref
                .read(dashboardControllerProvider.notifier)
                .genMealByWeeksToDB(requireComplete: true);

            final dailyDatasource = ref.read(
              dailyHealthTrackingLocalDatasourceProvider,
            );
            final profile = await dailyDatasource.fetchLatestProfile();
            final now = DateTime.now();
            final startDate = DateTime(now.year, now.month, now.day + 1);
            final tasks = await ref
                .read(aiServiceProvider)
                .generateDailyHealthTasks(
                  profile: profile,
                  startDate: startDate,
                );
            await dailyDatasource.seedGeneratedTasks(
              tasks,
              requireComplete: true,
              startDate: startDate,
            );
          };
        }),
      ],
      child: const BioAIApp(),
    ),
  );
}
