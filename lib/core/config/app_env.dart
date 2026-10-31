import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Safe origin information for diagnostics. Never use this to expose values.
enum AppEnvValueSource { dartDefine, dotEnv, bundledPublicConfig, missing }

class AppEnv {
  AppEnv._();

  static const String _bundledAuthConfigAsset = 'assets/config/auth.env';
  static const Set<String> _publicAuthKeys = {
    'API_BASE_URL',
    'PRIVACY_POLICY_URL',
    'ACCOUNT_DELETION_URL',
  };
  static Map<String, String> _bundledAuthValues = const {};

  static Future<void> loadOptionalDotEnv({
    String fileName = '.env',
    String bundledAuthFileName = _bundledAuthConfigAsset,
  }) async {
    try {
      await dotenv.load(fileName: fileName, isOptional: true);
    } catch (_) {
      // `.env` stays outside Flutter assets. Local development may still pass
      // it through --dart-define-from-file or provide a legacy dotenv asset.
    }

    await _loadBundledPublicAuthConfig(bundledAuthFileName);
  }

  static String requiredString(String key) {
    final value = maybeString(key);
    if (value != null) return value;
    throw StateError(
      'Missing required app configuration: $key. '
      'Provide it via --dart-define, local dotenv, or bundled public config.',
    );
  }

  static String? maybeString(String key) {
    return switch (valueSource(key)) {
      AppEnvValueSource.dartDefine => _clean(_fromDartDefine(key)),
      AppEnvValueSource.dotEnv => _clean(_fromDotEnv(key)),
      AppEnvValueSource.bundledPublicConfig => _clean(_bundledAuthValues[key]),
      AppEnvValueSource.missing => null,
    };
  }

  /// Returns only where a value was resolved from; the value itself is never
  /// included so this can be logged safely during app bootstrap.
  static AppEnvValueSource valueSource(String key) {
    if (_clean(_fromDartDefine(key)) != null) {
      return AppEnvValueSource.dartDefine;
    }
    if (_clean(_fromDotEnv(key)) != null) return AppEnvValueSource.dotEnv;
    if (_clean(_bundledAuthValues[key]) != null) {
      return AppEnvValueSource.bundledPublicConfig;
    }
    return AppEnvValueSource.missing;
  }

  static String? maybeStringWithLegacy(String key, String legacyKey) {
    return maybeString(key) ?? maybeString(legacyKey);
  }

  static bool boolValue(String key, {required bool defaultValue}) {
    final value = maybeString(key)?.toLowerCase();
    return switch (value) {
      'true' || '1' || 'yes' || 'y' => true,
      'false' || '0' || 'no' || 'n' => false,
      _ => defaultValue,
    };
  }

  static void clearBundledAuthConfigForTesting() {
    _bundledAuthValues = const {};
  }

  static Future<void> _loadBundledPublicAuthConfig(String fileName) async {
    try {
      final source = await rootBundle.loadString(fileName);
      _bundledAuthValues = _parsePublicAuthConfig(source);
    } catch (_) {
      _bundledAuthValues = const {};
    }
  }

  static Map<String, String> _parsePublicAuthConfig(String source) {
    final values = <String, String>{};

    for (final rawLine in source.split(RegExp(r'\r?\n'))) {
      var line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      if (line.startsWith('export ')) {
        line = line.substring('export '.length).trimLeft();
      }

      final separatorIndex = line.indexOf('=');
      if (separatorIndex <= 0) continue;

      final key = line
          .substring(0, separatorIndex)
          .replaceFirst('\uFEFF', '')
          .trim();
      if (!_publicAuthKeys.contains(key)) continue;

      var value = line.substring(separatorIndex + 1).trim();
      if (value.length >= 2) {
        final first = value[0];
        final last = value[value.length - 1];
        if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
          value = value.substring(1, value.length - 1).trim();
        }
      }

      final cleaned = _clean(value);
      if (cleaned != null) values[key] = cleaned;
    }

    return Map.unmodifiable(values);
  }

  static String? _fromDotEnv(String key) {
    if (!dotenv.isInitialized) return null;
    try {
      return dotenv.env[key];
    } catch (_) {
      return null;
    }
  }

  static String? _fromDartDefine(String key) {
    return switch (key) {
      'API_BASE_URL' => const String.fromEnvironment('API_BASE_URL'),
      'OPENAI_BASE_URL' => const String.fromEnvironment('OPENAI_BASE_URL'),
      'PRIVACY_POLICY_URL' => const String.fromEnvironment(
        'PRIVACY_POLICY_URL',
      ),
      'ACCOUNT_DELETION_URL' => const String.fromEnvironment(
        'ACCOUNT_DELETION_URL',
      ),
      'ONBOARDING_AI_DEV_CHECK_ENABLED' => const String.fromEnvironment(
        'ONBOARDING_AI_DEV_CHECK_ENABLED',
      ),
      'NABI_AI_CARE_ENABLED' => const String.fromEnvironment(
        'NABI_AI_CARE_ENABLED',
      ),
      _ => null,
    };
  }

  static String? _clean(String? value) {
    var cleaned = value?.replaceFirst('\uFEFF', '').trim();
    if (cleaned == null || cleaned.isEmpty) return null;

    if (cleaned.length >= 2) {
      final first = cleaned[0];
      final last = cleaned[cleaned.length - 1];
      if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
        cleaned = cleaned.substring(1, cleaned.length - 1).trim();
      }
    }

    return cleaned.isEmpty ? null : cleaned;
  }
}
