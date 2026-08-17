import 'package:flutter/foundation.dart';

/// Centralized debug logger with privacy-safe defaults.
///
/// User identifiers, health-derived values, raw exceptions, stack traces and
/// arbitrary form values are intentionally not emitted.
class AppLogger {
  AppLogger._();

  static const _enableLogging = kDebugMode;

  static void info(String tag, String message) {
    _print(tag, 'INFO', message);
  }

  static void success(String tag, String message) {
    _print(tag, 'SUCCESS', message);
  }

  static void warning(String tag, String message) {
    _print(tag, 'WARNING', message);
  }

  static void error(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!_enableLogging) return;
    debugPrint('[$tag][ERROR] ${_redactMessage(message)}');
    if (error != null) {
      debugPrint('ErrorType: ${error.runtimeType}');
    }
    // Stack traces are intentionally suppressed. They frequently contain
    // request URLs, local paths or upstream payload fragments.
  }

  static void validation(
    String tag,
    String field,
    bool passed, {
    String? reason,
  }) {
    if (!_enableLogging) return;
    final status = passed ? 'Passed' : 'Failed';
    debugPrint('[$tag][VALIDATION] ${_safeLabel(field)} - $status');
    if (!passed && reason != null) {
      debugPrint('Reason: ${_redactMessage(reason)}');
    }
  }

  static void form(String tag, String field, dynamic value) {
    if (!_enableLogging) return;
    debugPrint(
      '[$tag][FORM] ${_safeLabel(field)} = ${_safeFormValue(value)}',
    );
  }

  static void navigation(String tag, String from, String to) {
    if (!_enableLogging) return;
    debugPrint(
      '[$tag][ROUTER] Navigate: ${_redactMessage(from)} → ${_redactMessage(to)}',
    );
  }

  static void provider(String tag, String description) {
    _print(tag, 'PROVIDER', description);
  }

  static void database(String tag, String operation) {
    _print(tag, 'LOCAL_DB', operation);
  }

  static void supabase(String tag, String operation) {
    _print(tag, 'SUPABASE', operation);
  }

  static void action(String tag, String action) {
    if (!_enableLogging) return;
    debugPrint('[$tag] ${_redactMessage(action)}');
  }

  static void summary(String tag, String title, Map<String, dynamic> data) {
    if (!_enableLogging) return;
    debugPrint('[$tag][SUMMARY] ${_safeLabel(title)}');
    data.forEach((key, value) {
      debugPrint('  - ${_safeLabel(key)}: ${_safeSummaryValue(key, value)}');
    });
  }

  static void separator([String tag = 'LOG']) {
    if (!_enableLogging) return;
    debugPrint('[$tag] ${'=' * 60}');
  }

  static void _print(String tag, String level, String message) {
    if (!_enableLogging) return;
    debugPrint('[$tag][$level] ${_redactMessage(message)}');
  }

  static String _safeFormValue(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text == 'provided' ||
        text == 'empty' ||
        text == 'accepted' ||
        text == 'not_accepted') {
      return text;
    }
    if (RegExp(r'^count=\d+$').hasMatch(text)) return text;
    return 'updated';
  }

  static String _safeSummaryValue(String key, Object? value) {
    if (_isSensitiveKey(key)) return '[REDACTED]';
    if (value is bool) return value.toString();
    if (value is num && _isSafeCounterKey(key)) return value.toString();

    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return 'empty';
    if (_isSafeStatusKey(key) && _isSafeStatusToken(text)) {
      return text;
    }
    return 'recorded';
  }

  static bool _isSafeCounterKey(String key) {
    final normalized = key.toLowerCase();
    return normalized.contains('count') ||
        normalized.contains('total steps') ||
        normalized.contains('completed steps');
  }

  static bool _isSafeStatusKey(String key) {
    final normalized = key.toLowerCase();
    return normalized.contains('status') ||
        normalized.contains('type') ||
        normalized.contains('source');
  }

  static bool _isSafeStatusToken(String value) {
    return RegExp(r'^[A-Za-z0-9_. -]{1,80}$').hasMatch(value);
  }

  static bool _isSensitiveKey(String key) {
    return RegExp(
      r'(user|subject|email|phone|token|secret|password|path|payload|prompt|response|score|bmi|weight|height|condition|medication|treatment|allergy|health)',
      caseSensitive: false,
    ).hasMatch(key);
  }

  static String _safeLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'event';
    return trimmed.length <= 80 ? trimmed : '${trimmed.substring(0, 77)}...';
  }

  static String _redactMessage(String message) {
    var result = message;
    result = result.replaceAll(
      RegExp(r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}', caseSensitive: false),
      '[REDACTED_EMAIL]',
    );
    result = result.replaceAll(
      RegExp(r'\+?\d[\d .-]{7,}\d'),
      '[REDACTED_NUMBER]',
    );
    result = result.replaceAll(
      RegExp(
        r'\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b',
        caseSensitive: false,
      ),
      '[REDACTED_ID]',
    );
    result = result.replaceAllMapped(
      RegExp(
        r'\b(user(?:_?id)?|subject(?:_?id)?|email|phone|token|secret|password|path|payload|prompt|response|score|bmi|weight|height)\s*[:=]\s*([^\s,;]+)',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}=[REDACTED]',
    );
    return result;
  }
}
