import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bio_ai_app.dart';
import 'app/health_orchestration/health_orchestration_providers.dart';
import 'app_versions/admin/features/admin_panel/providers/admin_providers.dart';
import 'app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'app_versions/v1/features/onboarding/providers/onboarding_completion_provider.dart';
import 'app_versions/v1/services/ai/ai_exceptions.dart';
import 'app_versions/v1/services/notifications/notification_bootstrap.dart';
import 'app_versions/v1/services/notifications/notification_lifecycle_refresher.dart';
import 'app_versions/v1/services/notifications/notification_startup_scheduler.dart';
import 'app_versions/v2/features/auth/providers/auth_providers.dart';
import 'core/config/app_env.dart';
import 'core/config/auth_backend_availability.dart';
import 'core/network/backend_api_client.dart';
import 'core/storage/localdb/app_prefs.dart';
import 'core/storage/localdb/sync/local_user_data_sync_dispatcher.dart';
import 'core/utils/logger/app_error_capture.dart';
import 'core/utils/logger/app_log_category.dart';
import 'core/utils/logger/app_log_level.dart';
import 'core/utils/logger/app_logger.dart';
import 'core/utils/logger/app_provider_observer.dart';
import 'services/health_orchestration/health_domain_event_sink.dart';
import 'services/backend/cloud_sync/user_data_sync_outbox.dart';
import 'services/backend/cloud_sync/user_data_sync_outbox_refresher.dart';
import 'services/backend/auth/current_backend_user.dart';

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
  final authBackendAvailability = await _initializeBackend();

  runApp(
    ProviderScope(
      observers: const [AppProviderObserver()],
      overrides: [
        healthDomainEventSinkProvider.overrideWith(
          (ref) => ref.watch(appHealthEventDispatcherProvider),
        ),
        authBackendAvailabilityProvider.overrideWithValue(
          authBackendAvailability,
        ),
        adminBackendAvailabilityProvider.overrideWithValue(
          authBackendAvailability,
        ),
        onboardingCompletionCallbackProvider.overrideWith((ref) {
          return ({onProgress}) async {
            if (currentBackendUserIdOrNull() == null) {
              throw const AIAuthenticationException();
            }
            final result = await ref
                .read(generatedPlanServiceProvider)
                .generateInitialGuestPlan(days: 7, onProgress: onProgress);
            if (result.awaitingMealApproval &&
                result.pendingMealProposal != null) {
              return OnboardingCompletionResult.awaitingCustomMeal(
                requestId: result.requestId,
                proposal: result.pendingMealProposal!,
              );
            }
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

Future<AuthBackendAvailability> _initializeBackend() async {
  final baseUrl =
      AppEnv.maybeString('API_BASE_URL') ?? defaultBackendApiBaseUrl;
  final stopwatch = Stopwatch()..start();
  final availability = await initializeAuthBackendAvailability(
    baseUrl: baseUrl,
    initialize: (resolvedBaseUrl) async {
      BackendApiClient.configure(baseUrl: resolvedBaseUrl);
      await BackendApiClient.shared.restoreSession();
    },
    onInitializationError: (error, stackTrace) {
      AppLogger.captureError(
        category: AppLogCategory.app,
        scope: _bootstrapTag,
        operation: 'BACKEND_INITIALIZE',
        message: 'Self-hosted backend client configuration failed',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
  stopwatch.stop();
  AppLogger.event(
    level: availability.isReady ? AppLogLevel.info : AppLogLevel.warn,
    category: AppLogCategory.app,
    scope: _bootstrapTag,
    operation: 'BACKEND_INITIALIZE',
    message: availability.isReady
        ? 'Self-hosted backend client configured'
        : 'Self-hosted backend unavailable; guest mode starts',
    duration: stopwatch.elapsed,
    metadata: {'availability': availability.name},
  );
  return availability;
}

Future<void> _startPostLaunchServices(
  AuthBackendAvailability backendAvailability,
) async {
  if (backendAvailability.isReady) {
    _startCloudSync();
  }

  await _startNotificationsSafely();
}

void _startCloudSync() {
  AppLogger.event(
    level: AppLogLevel.info,
    category: AppLogCategory.app,
    scope: _bootstrapTag,
    operation: 'CLOUD_SYNC',
    message: 'Backend cloud sync dispatcher starting',
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
