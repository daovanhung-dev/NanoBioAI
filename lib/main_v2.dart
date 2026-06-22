import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'app_versions/v1/features/onboarding/providers/onboarding_completion_provider.dart';
import 'app_versions/v1/services/notifications/notification_bootstrap.dart';
import 'app_versions/v1/services/notifications/notification_lifecycle_refresher.dart';
import 'app_versions/v1/services/notifications/notification_startup_scheduler.dart';
import 'app_versions/v2/app/bio_ai_v2_app.dart';
import 'core/storage/localdb/app_prefs.dart';

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
            await ref
                .read(generatedPlanServiceProvider)
                .generateInitialGuestPlan(days: 7);
            return const OnboardingCompletionResult.generatedInitialPlan();
          };
        }),
      ],
      child: const BioAIV2App(),
    ),
  );
}
