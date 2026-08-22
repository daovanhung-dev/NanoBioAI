import 'package:nano_app/core/utils/logger/app_logger.dart';

class VoiceLatencyTrace {
  static const _tag = 'VOICE_LATENCY';

  final String traceId;
  final DateTime _startedAt;
  DateTime _lastMark;

  VoiceLatencyTrace(this.traceId)
      : _startedAt = DateTime.now(),
        _lastMark = DateTime.now();

  void mark(String stage) {
    final now = DateTime.now();
    final totalMs = now.difference(_startedAt).inMilliseconds;
    final deltaMs = now.difference(_lastMark).inMilliseconds;
    _lastMark = now;
    AppLogger.info(
      _tag,
      'stage=$stage totalMs=$totalMs deltaMs=$deltaMs',
    );
  }
}
