import 'package:dio/dio.dart';

import 'app_log_category.dart';
import 'app_log_level.dart';
import 'app_logger.dart';
import 'log_redactor.dart';

class DioLogInterceptor extends Interceptor {
  DioLogInterceptor({required this.scope});

  static const _correlationKey = 'nanobio.log.correlation_id';
  static const _startedAtKey = 'nanobio.log.started_at_micros';

  final String scope;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final correlationId = options.extra[_correlationKey]?.toString() ??
        AppLogger.newCorrelationId('http');
    options.extra[_correlationKey] = correlationId;
    options.extra[_startedAtKey] = DateTime.now().microsecondsSinceEpoch;

    AppLogger.event(
      level: AppLogLevel.debug,
      category: AppLogCategory.http,
      scope: scope,
      operation: 'REQUEST',
      message: '${options.method.toUpperCase()} ${LogRedactor.sanitizeUri(options.uri)}',
      correlationId: correlationId,
      metadata: {
        'method': options.method.toUpperCase(),
        'connectTimeoutMs': options.connectTimeout?.inMilliseconds,
        'sendTimeoutMs': options.sendTimeout?.inMilliseconds,
        'receiveTimeoutMs': options.receiveTimeout?.inMilliseconds,
        'contentType': options.contentType,
        'responseType': options.responseType.name,
      },
    );
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final options = response.requestOptions;
    final correlationId = options.extra[_correlationKey]?.toString();
    final duration = _durationFor(options);
    AppLogger.event(
      level: AppLogLevel.info,
      category: AppLogCategory.http,
      scope: scope,
      operation: 'RESPONSE',
      message: '${options.method.toUpperCase()} ${LogRedactor.sanitizeUri(options.uri)}',
      correlationId: correlationId,
      duration: duration,
      metadata: {
        'statusCode': response.statusCode,
        'responseType': options.responseType.name,
      },
    );
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    final options = error.requestOptions;
    final correlationId = options.extra[_correlationKey]?.toString();
    AppLogger.captureError(
      category: AppLogCategory.http,
      scope: scope,
      operation: 'ERROR',
      message: '${options.method.toUpperCase()} ${LogRedactor.sanitizeUri(options.uri)}',
      error: error,
      stackTrace: error.stackTrace,
      correlationId: correlationId,
      duration: _durationFor(options),
      metadata: {
        'statusCode': error.response?.statusCode,
        'dioType': error.type.name,
      },
    );
    handler.next(error);
  }

  static Duration? _durationFor(RequestOptions options) {
    final startedAt = options.extra[_startedAtKey];
    if (startedAt is! int) return null;
    final elapsed = DateTime.now().microsecondsSinceEpoch - startedAt;
    return Duration(microseconds: elapsed < 0 ? 0 : elapsed);
  }
}

Dio attachDioLogging(Dio dio, {required String scope}) {
  final alreadyAttached = dio.interceptors.any(
    (interceptor) => interceptor is DioLogInterceptor,
  );
  if (!alreadyAttached) {
    dio.interceptors.add(DioLogInterceptor(scope: scope));
  }
  return dio;
}
