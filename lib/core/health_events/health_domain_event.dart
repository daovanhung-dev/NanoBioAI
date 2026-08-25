import 'health_event_priority.dart';
import 'health_event_type.dart';

class HealthDomainEvent {
  static int _sequence = 0;

  final String eventId;
  final HealthEventType type;
  final String subjectId;
  final String sourceFeature;
  final String? entityId;
  final DateTime occurredAt;
  final String correlationId;
  final String? causationId;
  final Set<String> changedFields;
  final HealthEventPriority priority;

  const HealthDomainEvent({
    required this.eventId,
    required this.type,
    required this.subjectId,
    required this.sourceFeature,
    required this.occurredAt,
    required this.correlationId,
    this.entityId,
    this.causationId,
    this.changedFields = const <String>{},
    this.priority = HealthEventPriority.normal,
  });

  factory HealthDomainEvent.create({
    required HealthEventType type,
    required String subjectId,
    required String sourceFeature,
    String? entityId,
    DateTime? occurredAt,
    String? eventId,
    String? correlationId,
    String? causationId,
    Set<String> changedFields = const <String>{},
    HealthEventPriority priority = HealthEventPriority.normal,
  }) {
    final normalizedSubject = subjectId.trim();
    if (normalizedSubject.isEmpty) {
      throw ArgumentError.value(subjectId, 'subjectId', 'must not be empty');
    }
    final normalizedSource = sourceFeature.trim();
    if (normalizedSource.isEmpty) {
      throw ArgumentError.value(
        sourceFeature,
        'sourceFeature',
        'must not be empty',
      );
    }
    final timestamp = occurredAt ?? DateTime.now();
    final generatedEventId = eventId?.trim().isNotEmpty == true
        ? eventId!.trim()
        : _newEventId(type, timestamp);
    final generatedCorrelationId = correlationId?.trim().isNotEmpty == true
        ? correlationId!.trim()
        : generatedEventId;
    return HealthDomainEvent(
      eventId: generatedEventId,
      type: type,
      subjectId: normalizedSubject,
      sourceFeature: normalizedSource,
      entityId: _nonEmpty(entityId),
      occurredAt: timestamp,
      correlationId: generatedCorrelationId,
      causationId: _nonEmpty(causationId),
      changedFields: Set.unmodifiable(
        changedFields.map((item) => item.trim()).where((item) => item.isNotEmpty),
      ),
      priority: priority,
    );
  }

  String get dedupeKey => [
        subjectId,
        type.wireName,
        entityId ?? '-',
        correlationId,
      ].join('|');

  static String _newEventId(HealthEventType type, DateTime timestamp) {
    final sequence = _sequence++;
    return '${timestamp.toUtc().microsecondsSinceEpoch}-$sequence-${type.wireName}';
  }

  static String? _nonEmpty(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
