import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'app_log_category.dart';
import 'app_log_level.dart';
import 'app_logger.dart';

class AppErrorCapture {
  AppErrorCapture._();

  static bool _installed = false;
  static FlutterExceptionHandler? _previousFlutterHandler;
  static ErrorCallback? _previousPlatformHandler;
  static DebugPrintCallback? _previousDebugPrint;

  static void install() {
    if (_installed) return;
    _installed = true;

    _previousDebugPrint = debugPrint;
    debugPrint = _captureDebugPrint;

    _previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      AppLogger.captureError(
        category: AppLogCategory.ui,
        scope: details.library ?? 'FlutterFramework',
        operation: 'FRAMEWORK_ERROR',
        message: details.context?.toDescription() ?? 'Flutter framework error',
        error: details.exception,
        stackTrace: details.stack ?? StackTrace.current,
      );
    };

    _previousPlatformHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      AppLogger.captureError(
        category: AppLogCategory.app,
        scope: 'PlatformDispatcher',
        operation: 'UNCAUGHT_ASYNC_ERROR',
        message: 'Uncaught platform/async error',
        error: error,
        stackTrace: stackTrace,
        level: AppLogLevel.fatal,
      );
      final previous = _previousPlatformHandler;
      if (previous != null) return previous(error, stackTrace);
      return true;
    };
  }

  static void captureZoneError(Object error, StackTrace stackTrace) {
    AppLogger.captureError(
      category: AppLogCategory.app,
      scope: 'RootZone',
      operation: 'UNCAUGHT_ZONE_ERROR',
      message: 'Uncaught asynchronous error escaped the root zone',
      error: error,
      stackTrace: stackTrace,
      level: AppLogLevel.fatal,
    );
  }

  static void _captureDebugPrint(String? message, {int? wrapWidth}) {
    AppLogger.legacyPrint(message, source: 'debugPrint');
  }

  @visibleForTesting
  static void restoreForTesting() {
    if (!_installed) return;
    if (_previousDebugPrint != null) debugPrint = _previousDebugPrint!;
    FlutterError.onError = _previousFlutterHandler;
    PlatformDispatcher.instance.onError = _previousPlatformHandler;
    _installed = false;
  }
}
