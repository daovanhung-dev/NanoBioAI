import 'package:nano_app/core/health_events/health_domain_event.dart';
import 'package:nano_app/core/health_events/health_event_impact.dart';

abstract interface class HealthEventHandler {
  Future<void> handle(HealthDomainEvent event, HealthEventImpact impact);
}
