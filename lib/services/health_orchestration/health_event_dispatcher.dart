import 'package:nano_app/core/health_events/health_domain_event.dart';

import 'health_domain_event_sink.dart';
import 'health_event_deduplicator.dart';
import 'health_event_handler.dart';
import 'health_event_impact_registry.dart';
import 'health_orchestration_result.dart';

class HealthEventDispatcher implements HealthDomainEventSink {
  final List<HealthEventHandler> handlers;
  final HealthEventImpactRegistry impactRegistry;
  final HealthEventDeduplicator deduplicator;

  HealthEventDispatcher({
    required this.handlers,
    HealthEventImpactRegistry? impactRegistry,
    HealthEventDeduplicator? deduplicator,
  })  : impactRegistry = impactRegistry ?? const HealthEventImpactRegistry(),
        deduplicator = deduplicator ?? HealthEventDeduplicator();

  Future<HealthOrchestrationResult> dispatch(HealthDomainEvent event) async {
    if (!deduplicator.accept(event)) {
      return const HealthOrchestrationResult.duplicate();
    }
    final impact = impactRegistry.resolve(event);
    final errors = <Object>[];
    for (final handler in handlers) {
      try {
        await handler.handle(event, impact);
      } catch (error) {
        errors.add(error);
      }
    }
    return HealthOrchestrationResult(
      accepted: true,
      duplicate: false,
      handlerCount: handlers.length,
      handlerErrors: List.unmodifiable(errors),
    );
  }

  @override
  Future<void> publish(HealthDomainEvent event) async {
    await dispatch(event);
  }
}
