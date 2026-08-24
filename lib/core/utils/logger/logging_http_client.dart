import 'package:http/http.dart' as http;

import 'app_log_category.dart';
import 'app_log_level.dart';
import 'app_logger.dart';
import 'log_redactor.dart';

class LoggingHttpClient extends http.BaseClient {
  LoggingHttpClient(this._inner, {required this.scope});

  final http.Client _inner;
  final String scope;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final correlationId = AppLogger.newCorrelationId('http');
    final stopwatch = Stopwatch()..start();
    final safeUri = LogRedactor.sanitizeUri(request.url);

    AppLogger.event(
      level: AppLogLevel.debug,
      category: AppLogCategory.http,
      scope: scope,
      operation: 'REQUEST',
      message: '${request.method.toUpperCase()} $safeUri',
      correlationId: correlationId,
      metadata: {
        'method': request.method.toUpperCase(),
        'headerNames': request.headers.keys.toList(growable: false),
        'contentLength': request.contentLength,
      },
    );

    try {
      final response = await _inner.send(request);
      stopwatch.stop();
      AppLogger.event(
        level: AppLogLevel.info,
        category: AppLogCategory.http,
        scope: scope,
        operation: 'RESPONSE',
        message: '${request.method.toUpperCase()} $safeUri',
        correlationId: correlationId,
        duration: stopwatch.elapsed,
        metadata: {
          'statusCode': response.statusCode,
          'contentLength': response.contentLength,
        },
      );
      return response;
    } catch (error, stackTrace) {
      stopwatch.stop();
      AppLogger.captureError(
        category: AppLogCategory.http,
        scope: scope,
        operation: 'ERROR',
        message: '${request.method.toUpperCase()} $safeUri',
        error: error,
        stackTrace: stackTrace,
        correlationId: correlationId,
        duration: stopwatch.elapsed,
      );
      rethrow;
    }
  }

  @override
  void close() => _inner.close();
}
