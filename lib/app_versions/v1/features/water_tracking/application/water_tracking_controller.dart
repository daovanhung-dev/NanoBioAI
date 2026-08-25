import 'package:nano_app/core/health_events/health_domain_event.dart';
import 'package:nano_app/core/health_events/health_event_type.dart';
import 'package:nano_app/services/health_orchestration/health_domain_event_sink.dart';

import '../domain/water_tracking_repository.dart';
import '../domain/water_tracking_snapshot.dart';

class WaterTrackingController {
  final WaterTrackingRepository repository;
  final HealthDomainEventSink eventSink;
  final Future<String?> Function() resolveSubjectId;

  const WaterTrackingController({
    required this.repository,
    required this.eventSink,
    required this.resolveSubjectId,
  });

  Future<WaterTrackingSnapshot> load(DateTime localDay) {
    return repository.load(localDay);
  }

  Future<void> saveTargetMl(int targetMl) async {
    await repository.saveTargetMl(targetMl);
    await _publish(
      HealthEventType.waterTargetUpdated,
      changedFields: const {'hydration_target_ml'},
    );
  }

  Future<WaterTrackingSnapshot> addWater({
    required DateTime localDay,
    required WaterTrackingSnapshot current,
    required int amountMl,
  }) async {
    final nextAmount = (current.amountMl + amountMl).clamp(0, 100000);
    await repository.saveAmountMl(localDay, nextAmount);

    final subjectId = await _resolvedSubjectOrNull();
    if (subjectId != null) {
      final logged = HealthDomainEvent.create(
        type: HealthEventType.waterLogged,
        subjectId: subjectId,
        sourceFeature: 'water_tracking',
        entityId: _dateKey(localDay),
        changedFields: const {'water_ml'},
      );
      await eventSink.publish(logged);

      final target = current.targetMl;
      if (target != null && current.amountMl < target && nextAmount >= target) {
        await eventSink.publish(
          HealthDomainEvent.create(
            type: HealthEventType.waterGoalReached,
            subjectId: subjectId,
            sourceFeature: 'water_tracking',
            entityId: _dateKey(localDay),
            correlationId: logged.correlationId,
            causationId: logged.eventId,
            changedFields: const {'water_ml', 'hydration_target_ml'},
          ),
        );
      }
    }

    return WaterTrackingSnapshot(
      targetMl: current.targetMl,
      amountMl: nextAmount,
    );
  }

  Future<void> _publish(
    HealthEventType type, {
    Set<String> changedFields = const <String>{},
  }) async {
    final subjectId = await _resolvedSubjectOrNull();
    if (subjectId == null) return;
    await eventSink.publish(
      HealthDomainEvent.create(
        type: type,
        subjectId: subjectId,
        sourceFeature: 'water_tracking',
        changedFields: changedFields,
      ),
    );
  }

  Future<String?> _resolvedSubjectOrNull() async {
    try {
      final value = (await resolveSubjectId())?.trim();
      return value == null || value.isEmpty ? null : value;
    } catch (_) {
      // Persistence is already committed. Cross-feature enrichment must never
      // turn a successful local health write into a user-visible failure.
      return null;
    }
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
