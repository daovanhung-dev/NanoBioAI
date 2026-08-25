import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/health_events/health_domain_event.dart';

abstract interface class HealthDomainEventSink {
  Future<void> publish(HealthDomainEvent event);
}

class NoopHealthDomainEventSink implements HealthDomainEventSink {
  const NoopHealthDomainEventSink();

  @override
  Future<void> publish(HealthDomainEvent event) async {}
}

final healthDomainEventSinkProvider = Provider<HealthDomainEventSink>(
  (_) => const NoopHealthDomainEventSink(),
);
