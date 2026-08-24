import 'app_log_category.dart';
import 'app_log_level.dart';

class AppLogEvent {
  const AppLogEvent({
    required this.timestamp,
    required this.sequence,
    required this.level,
    required this.category,
    required this.scope,
    required this.operation,
    required this.message,
    this.correlationId,
    this.duration,
    this.metadata = const <String, Object?>{},
    this.errorType,
    this.stackTrace,
  });

  final DateTime timestamp;
  final int sequence;
  final AppLogLevel level;
  final AppLogCategory category;
  final String scope;
  final String operation;
  final String message;
  final String? correlationId;
  final Duration? duration;
  final Map<String, Object?> metadata;
  final String? errorType;
  final String? stackTrace;
}
