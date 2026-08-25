import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/services/health_orchestration/health_event_dispatcher.dart';
import 'package:nano_app/services/health_orchestration/health_event_impact_registry.dart';

import 'app_health_event_handlers.dart';
import 'riverpod_health_projection_invalidator.dart';

final riverpodHealthProjectionInvalidatorProvider =
    Provider<RiverpodHealthProjectionInvalidator>((ref) {
  return RiverpodHealthProjectionInvalidator(ref);
});

final appNabiCareEventHandlerProvider = Provider<AppNabiCareEventHandler>((ref) {
  return AppNabiCareEventHandler(ref);
});

final appHealthEventDispatcherProvider = Provider<HealthEventDispatcher>((ref) {
  return HealthEventDispatcher(
    impactRegistry: const HealthEventImpactRegistry(),
    handlers: [
      AppProjectionRefreshHandler(
        ref.watch(riverpodHealthProjectionInvalidatorProvider),
      ),
      ref.watch(appNabiCareEventHandlerProvider),
      const AppNotificationReconciliationHandler(),
    ],
  );
});
