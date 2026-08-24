class LogRedactor {
  const LogRedactor._();

  static final RegExp _sensitiveKey = RegExp(
    r'(authorization|bearer|token|access[_-]?token|refresh[_-]?token|jwt|api[_-]?key|apikey|x-goog-api-key|password|passcode|pin|secret|cookie|session|email|phone|address|prompt|payload|response|conversation|health|condition|medication|treatment|allergy|weight|height|bmi|score|image|audio)',
    caseSensitive: false,
  );

  static final RegExp _email = RegExp(
    r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
    caseSensitive: false,
  );
  static final RegExp _phone = RegExp(r'\+?\d[\d .()-]{7,}\d');
  static final RegExp _uuid = RegExp(
    r'\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b',
    caseSensitive: false,
  );
  static final RegExp _jwt = RegExp(
    r'\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}(?:\.[A-Za-z0-9_-]{4,})?\b',
  );
  static final RegExp _bearer = RegExp(
    r'Bearer\s+[A-Za-z0-9._~+\-/]+=*',
    caseSensitive: false,
  );
  static final RegExp _keyValueSecret = RegExp(
    r'\b(user(?:_?id)?|subject(?:_?id)?|authorization|token|access[_-]?token|refresh[_-]?token|jwt|api[_-]?key|apikey|x-goog-api-key|password|passcode|pin|secret|cookie|session|email|phone|score|bmi|weight|height|condition|medication|treatment|allergy|health)\s*[:=]\s*([^\s,;]+)',
    caseSensitive: false,
  );

  static String text(Object? value, {int maxLength = 900}) {
    var result = value?.toString() ?? '';
    result = result.replaceAll(_email, '[REDACTED_EMAIL]');
    result = result.replaceAll(_phone, '[REDACTED_NUMBER]');
    result = result.replaceAll(_uuid, '[REDACTED_ID]');
    result = result.replaceAll(_jwt, '[REDACTED_TOKEN]');
    result = result.replaceAll(_bearer, 'Bearer [REDACTED]');
    result = result.replaceAllMapped(
      _keyValueSecret,
      (match) => '${match.group(1)}=[REDACTED]',
    );
    if (result.length > maxLength) {
      result = '${result.substring(0, maxLength)}…[TRUNCATED]';
    }
    return result;
  }

  static Object? value(String key, Object? raw, {int depth = 0}) {
    if (_sensitiveKey.hasMatch(key)) return '[REDACTED]';
    if (depth > 4) return '[MAX_DEPTH]';
    if (raw == null || raw is bool || raw is num) return raw;
    if (raw is String) return text(raw, maxLength: 240);
    if (raw is Uri) return sanitizeUri(raw);
    if (raw is Map) {
      final result = <String, Object?>{};
      raw.forEach((mapKey, mapValue) {
        final normalizedKey = mapKey.toString();
        result[normalizedKey] = value(
          normalizedKey,
          mapValue,
          depth: depth + 1,
        );
      });
      return result;
    }
    if (raw is Iterable) {
      return raw
          .take(20)
          .map((item) => value('item', item, depth: depth + 1))
          .toList(growable: false);
    }
    return text(raw.runtimeType.toString(), maxLength: 120);
  }

  static Map<String, Object?> metadata(Map<String, Object?> raw) {
    return raw.map(
      (key, value_) => MapEntry(key, value(key, value_)),
    );
  }

  static String sanitizeUri(Uri uri) {
    final path = text(uri.path, maxLength: 260).replaceAll(
      RegExp(r'/\d{5,}(?=/|$)'),
      '/[REDACTED_ID]',
    );
    final queryKeys = uri.queryParametersAll.keys.toList()..sort();
    if (queryKeys.isEmpty) return path.isEmpty ? '/' : path;
    return '${path.isEmpty ? '/' : path}?keys=${queryKeys.join(',')}';
  }

  static String stack(StackTrace stackTrace, {int maxLines = 24}) {
    final lines = stackTrace.toString().split('\n');
    final sanitized = <String>[];
    for (final rawLine in lines) {
      if (sanitized.length >= maxLines) break;
      var line = text(rawLine, maxLength: 500);
      line = line.replaceAllMapped(
        RegExp(r'(?:file://)?/[^\s]*/lib/([^\s)]+)'),
        (match) => 'package:nano_app/${match.group(1)}',
      );
      sanitized.add(line);
    }
    return sanitized.join('\n');
  }
}
