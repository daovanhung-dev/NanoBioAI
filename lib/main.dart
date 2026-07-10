import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_versions/v2/app/bio_ai_v2_app.dart';
import 'core/config/app_env.dart';
import 'core/storage/localdb/app_prefs.dart';
import 'core/storage/localdb/sync/local_user_data_sync_dispatcher.dart';
import 'services/supabase/cloud_sync/user_data_sync_outbox.dart';
import 'services/supabase/cloud_sync/user_data_sync_outbox_refresher.dart';
import 'app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'app_versions/v1/features/onboarding/providers/onboarding_completion_provider.dart';
import 'app_versions/v1/services/notifications/notification_bootstrap.dart';
import 'app_versions/v1/services/notifications/notification_lifecycle_refresher.dart';
import 'app_versions/v1/services/notifications/notification_startup_scheduler.dart';

const _bootstrapTag = 'APP_BOOTSTRAP';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppEnv.loadOptionalDotEnv();
  final supabaseInitialized = await _initializeSupabaseIfConfigured();

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

  unawaited(_startPostLaunchServices(supabaseInitialized));
}

Future<bool> _initializeSupabaseIfConfigured() async {
  final config = AppEnv.maybeSupabaseConfig();
  if (config == null) {
    debugPrint('$_bootstrapTag: Supabase config missing; guest mode starts.');
    return false;
  }

  try {
    await Supabase.initialize(url: config.url, anonKey: config.anonKey);
    return true;
  } catch (error, stackTrace) {
    debugPrint('$_bootstrapTag: Supabase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    return false;
  }
}

Future<void> _startPostLaunchServices(bool supabaseInitialized) async {
  if (supabaseInitialized) {
    _startCloudSync();
  }

  await _startNotificationsSafely();
}

void _startCloudSync() {
  LocalUserDataSyncDispatcher.register(
    UserDataSyncOutbox.requestImmediateDrain,
  );
  UserDataSyncOutboxRefresher.shared.start();
}

Future<void> _startNotificationsSafely() async {
  try {
    await NotificationBootstrap.initialize();
    NotificationLifecycleRefresher(
      startupScheduler: NotificationStartupScheduler(
        isOnboardingCompleted: AppPrefs.isOnboardingCompleted,
        scheduleGeneratedReminders:
            NotificationBootstrap.scheduleGeneratedReminders,
      ),
    ).start();
  } catch (error, stackTrace) {
    debugPrint('$_bootstrapTag: Notification startup failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
