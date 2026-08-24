import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/bio_ai_app.dart';
import 'app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'app_versions/v2/features/auth/providers/auth_providers.dart';
import 'core/config/app_env.dart';
import 'core/config/auth_backend_availability.dart';
import 'core/storage/localdb/app_prefs.dart';
import 'core/storage/localdb/sync/local_user_data_sync_dispatcher.dart';
import 'core/utils/logger/app_error_capture.dart';
import 'core/utils/logger/app_log_category.dart';
import 'core/utils/logger/app_log_level.dart';
import 'core/utils/logger/app_logger.dart';
import 'core/utils/logger/app_provider_observer.dart';
import 'core/utils/logger/logging_http_client.dart';
import 'services/supabase/cloud_sync/user_data_sync_outbox.dart';
import 'services/supabase/cloud_sync/user_data_sync_outbox_refresher.dart';
import 'services/supabase/meal_catalog/meal_catalog_cache_refresh_service.dart';
import 'app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'app_versions/v1/features/onboarding/providers/onboarding_completion_provider.dart';
import 'app_versions/v1/services/notifications/notification_bootstrap.dart';
import 'app_versions/v1/services/notifications/notification_lifecycle_refresher.dart';
import 'app_versions/v1/services/notifications/notification_startup_scheduler.dart';

const _bootstrapTag = 'APP_BOOTSTRAP';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      AppErrorCapture.install();
      await _bootstrapApplication();
    },
    AppErrorCapture.captureZoneError,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        AppLogger.legacyPrint(line, source: 'print');
      },
    ),
  );
}

Future<void> _bootstrapApplication() async {
  final bootstrapStopwatch = Stopwatch()..start();
  AppLogger.event(
    level: AppLogLevel.info,
    category: AppLogCategory.app,
    scope: _bootstrapTag,
    operation: 'BOOT',
    message: 'Application bootstrap started',
  );

  await AppEnv.loadOptionalDotEnv();
  _logRuntimeConfigStatus();
  final authBackendAvailability = await _initializeSupabaseIfConfigured();

  runApp(
    ProviderScope(
      observers: const [AppProviderObserver()],
      overrides: [
        authBackendAvailabilityProvider.overrideWithValue(
          authBackendAvailability,
        ),
        adminBackendAvailabilityProvider.overrideWithValue(
          authBackendAvailability,
        ),
        onboardingCompletionCallbackProvider.overrideWith((ref) {
          return () async {
            await _prepareMealCatalogForOnboarding(authBackendAvailability);
            final result = await ref
                .read(generatedPlanServiceProvider)
                .generateInitialGuestPlan(days: 7);
            return OnboardingCompletionResult.generatedInitialPlan(
              generationSource: result.generationSource,
            );
          };
        }),
      ],
      child: const BioAIApp(),
    ),
  );

  bootstrapStopwatch.stop();
  AppLogger.event(
    level: AppLogLevel.info,
    category: AppLogCategory.app,
    scope: _bootstrapTag,
    operation: 'BOOT',
    message: 'Application bootstrap completed',
    duration: bootstrapStopwatch.elapsed,
    metadata: {'authBackend': authBackendAvailability.name},
  );

  unawaited(_startPostLaunchServices(authBackendAvailability));
}

void _logRuntimeConfigStatus() {
  final geminiConfigSource = AppEnv.valueSource('GEMINI_API_KEY');
  AppLogger.event(
    level: AppLogLevel.info,
    category: AppLogCategory.app,
    scope: _bootstrapTag,
    operation: 'RUNTIME_CONFIG',
    message: 'Gemini runtime configuration resolved',
    metadata: {
      'present': geminiConfigSource != AppEnvValueSource.missing,
      'source': geminiConfigSource.name,
    },
  );
}

Future<AuthBackendAvailability> _initializeSupabaseIfConfigured() async {
  final config = AppEnv.maybeSupabaseConfig();
  final stopwatch = Stopwatch()..start();
  final availability = await initializeAuthBackendAvailability(
    config: config,
    initialize: (url, anonKey) async {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: false,
        httpClient: LoggingHttpClient(http.Client(), scope: 'Supabase'),
        authOptions: FlutterAuthClientOptions(
          detectSessionInUri: false,
          localStorage: SharedPreferencesLocalStorage(
            persistSessionKey: 'nanobio_user_auth_session',
          ),
        ),
      );
    },
    onInitializationError: (error, stackTrace) {
      AppLogger.captureError(
        category: AppLogCategory.supabase,
        scope: _bootstrapTag,
        operation: 'INITIALIZE',
        message: 'Supabase initialization failed; guest mode will continue',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
  stopwatch.stop();

  AppLogger.event(
    level: availability == AuthBackendAvailability.missingConfiguration
        ? AppLogLevel.warn
        : AppLogLevel.info,
    category: AppLogCategory.supabase,
    scope: _bootstrapTag,
    operation: 'INITIALIZE',
    message: availability == AuthBackendAvailability.missingConfiguration
        ? 'Supabase configuration missing; guest mode starts'
        : 'Supabase initialization resolved',
    duration: stopwatch.elapsed,
    metadata: {'availability': availability.name},
  );

  return availability;
}

Future<void> _startPostLaunchServices(
  AuthBackendAvailability authBackendAvailability,
) async {
  if (authBackendAvailability.isReady) {
    _startCloudSync();
    await _refreshMealCatalogSafely();
  }

  await _startNotificationsSafely();
}

Future<void> _prepareMealCatalogForOnboarding(
  AuthBackendAvailability authBackendAvailability,
) async {
  if (authBackendAvailability.isReady) {
    try {
      final refreshed =
          await MealCatalogCacheRefreshService.refreshFromInitializedSupabase();
      if (refreshed > 0) return;
    } catch (error, stackTrace) {
      AppLogger.captureError(
        category: AppLogCategory.supabase,
        scope: _bootstrapTag,
        operation: 'ONBOARDING_MEAL_CATALOG_REFRESH',
        message: 'Onboarding meal catalog refresh deferred',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  if (await MealCatalogCacheRefreshService.hasUsableLocalCatalog()) {
    return;
  }

  throw StateError(
    'Nabi chưa có dữ liệu thực đơn phù hợp để tạo lịch đầu tiên.',
  );
}

Future<void> _refreshMealCatalogSafely() async {
  final stopwatch = Stopwatch()..start();
  try {
    final refreshed =
        await MealCatalogCacheRefreshService.refreshFromInitializedSupabase();
    stopwatch.stop();
    AppLogger.event(
      level: AppLogLevel.info,
      category: AppLogCategory.supabase,
      scope: _bootstrapTag,
      operation: 'MEAL_CATALOG_REFRESH',
      message: 'Meal catalog cache refreshed',
      duration: stopwatch.elapsed,
      metadata: {'rows': refreshed},
    );
  } catch (error, stackTrace) {
    stopwatch.stop();
    AppLogger.captureError(
      category: AppLogCategory.supabase,
      scope: _bootstrapTag,
      operation: 'MEAL_CATALOG_REFRESH',
      message: 'Meal catalog refresh skipped',
      error: error,
      stackTrace: stackTrace,
      duration: stopwatch.elapsed,
    );
  }
}

void _startCloudSync() {
  AppLogger.event(
    level: AppLogLevel.info,
    category: AppLogCategory.supabase,
    scope: _bootstrapTag,
    operation: 'CLOUD_SYNC',
    message: 'Cloud sync dispatcher starting',
  );
  LocalUserDataSyncDispatcher.register(
    UserDataSyncOutbox.requestImmediateDrain,
  );
  UserDataSyncOutboxRefresher.shared.start();
}

Future<void> _startNotificationsSafely() async {
  final stopwatch = Stopwatch()..start();
  try {
    await NotificationBootstrap.initialize();
    NotificationLifecycleRefresher(
      startupScheduler: NotificationStartupScheduler(
        isOnboardingCompleted: AppPrefs.isOnboardingCompleted,
        scheduleGeneratedReminders:
            NotificationBootstrap.scheduleGeneratedReminders,
      ),
    ).start();
    stopwatch.stop();
    AppLogger.event(
      level: AppLogLevel.info,
      category: AppLogCategory.notification,
      scope: _bootstrapTag,
      operation: 'INITIALIZE',
      message: 'Notification services started',
      duration: stopwatch.elapsed,
    );
  } catch (error, stackTrace) {
    stopwatch.stop();
    AppLogger.captureError(
      category: AppLogCategory.notification,
      scope: _bootstrapTag,
      operation: 'INITIALIZE',
      message: 'Notification startup failed',
      error: error,
      stackTrace: stackTrace,
      duration: stopwatch.elapsed,
    );
  }
}
