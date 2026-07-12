import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'app_versions/v1/features/onboarding/providers/onboarding_completion_provider.dart';
import 'app_versions/v1/services/notifications/notification_bootstrap.dart';
import 'app_versions/v1/services/notifications/notification_lifecycle_refresher.dart';
import 'app_versions/v1/services/notifications/notification_startup_scheduler.dart';
import 'app_versions/v2/app/bio_ai_v2_app.dart';
import 'app_versions/v2/features/auth/providers/auth_providers.dart';
import 'core/config/app_env.dart';
import 'core/config/auth_backend_availability.dart';
import 'core/storage/localdb/app_prefs.dart';
import 'core/storage/localdb/sync/local_user_data_sync_dispatcher.dart';
import 'services/supabase/cloud_sync/user_data_sync_outbox.dart';
import 'services/supabase/cloud_sync/user_data_sync_outbox_refresher.dart';

const _bootstrapTag = 'APP_BOOTSTRAP';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppEnv.loadOptionalDotEnv();
  final authBackendAvailability = await _initializeSupabaseIfConfigured();

  runApp(
    ProviderScope(
      overrides: [
        authBackendAvailabilityProvider.overrideWithValue(
          authBackendAvailability,
        ),
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

  unawaited(_startPostLaunchServices(authBackendAvailability));
}

Future<AuthBackendAvailability> _initializeSupabaseIfConfigured() async {
  final config = AppEnv.maybeSupabaseConfig();
  final availability = await initializeAuthBackendAvailability(
    config: config,
    initialize: (url, anonKey) async {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        authOptions: FlutterAuthClientOptions(
          detectSessionInUri: false,
          localStorage: SharedPreferencesLocalStorage(
            persistSessionKey: 'nanobio_user_auth_session',
          ),
        ),
      );
    },
    onInitializationError: (error, stackTrace) {
      debugPrint('$_bootstrapTag: Supabase initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    },
  );

  if (availability == AuthBackendAvailability.missingConfiguration) {
    debugPrint('$_bootstrapTag: Supabase config missing; guest mode starts.');
  }

  return availability;
}

Future<void> _startPostLaunchServices(
  AuthBackendAvailability authBackendAvailability,
) async {
  if (authBackendAvailability.isReady) {
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
