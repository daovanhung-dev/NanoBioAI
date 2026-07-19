import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Safe origin information for diagnostics. Never use this to expose values.
enum AppEnvValueSource {
  dartDefine,
  dotEnv,
  nativeBuildConfig,
  bundledPublicConfig,
  missing,
}

class AppEnv {
  AppEnv._();

  static const String _bundledAuthConfigAsset = 'assets/config/auth.env';
  static const Set<String> _publicAuthKeys = {
    'SUPABASE_URL',
    'SUPABASE_ANON_KEY',
    'AUTH_EMAIL_REDIRECT_URL',
    'AUTH_CONFIRM_EMAIL_REQUIRED',
  };
  static const Set<String> _nativePrivateKeys = {'GEMINI_API_KEY'};
  static const MethodChannel _nativeRuntimeConfigChannel = MethodChannel(
    'com.example.nano_app/runtime_config',
  );

  static Map<String, String> _bundledAuthValues = const {};
  static Map<String, String> _nativeRuntimeValues = const {};

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

    await _loadNativeRuntimeConfig();
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
      AppEnvValueSource.nativeBuildConfig => _clean(_nativeRuntimeValues[key]),
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
    if (_clean(_nativeRuntimeValues[key]) != null) {
      return AppEnvValueSource.nativeBuildConfig;
    }
    if (_clean(_bundledAuthValues[key]) != null) {
      return AppEnvValueSource.bundledPublicConfig;
    }
    return AppEnvValueSource.missing;
  }

  static String? maybeStringWithLegacy(String key, String legacyKey) {
    return maybeString(key) ?? maybeString(legacyKey);
  }

  static ({String url, String anonKey})? maybeSupabaseConfig() {
    final url = maybeString('SUPABASE_URL');
    final anonKey = maybeString('SUPABASE_ANON_KEY');

    if (url == null || anonKey == null) return null;

    return (url: url, anonKey: anonKey);
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

  static void clearNativeRuntimeConfigForTesting() {
    _nativeRuntimeValues = const {};
  }

  static Future<void> _loadNativeRuntimeConfig() async {
    try {
      final raw = await _nativeRuntimeConfigChannel.invokeMethod<Object?>(
        'getPrivateRuntimeConfig',
      );
      if (raw is! Map) {
        _nativeRuntimeValues = const {};
        return;
      }

      final values = <String, String>{};
      for (final entry in raw.entries) {
        final key = entry.key.toString();
        if (!_nativePrivateKeys.contains(key)) continue;

        final value = _clean(entry.value?.toString());
        if (value != null) values[key] = value;
      }
      _nativeRuntimeValues = Map.unmodifiable(values);
    } catch (_) {
      // Non-Android platforms and tests have no native runtime config channel.
      _nativeRuntimeValues = const {};
    }
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
      'SUPABASE_URL' => const String.fromEnvironment('SUPABASE_URL'),
      'SUPABASE_ANON_KEY' => const String.fromEnvironment('SUPABASE_ANON_KEY'),
      'OPENAI_BASE_URL' => const String.fromEnvironment('OPENAI_BASE_URL'),
      'AUTH_DELETE_ACCOUNT_FUNCTION' => const String.fromEnvironment(
        'AUTH_DELETE_ACCOUNT_FUNCTION',
      ),
      'AUTH_CONFIRM_EMAIL_REQUIRED' => const String.fromEnvironment(
        'AUTH_CONFIRM_EMAIL_REQUIRED',
      ),
      'AUTH_EMAIL_REDIRECT_URL' => const String.fromEnvironment(
        'AUTH_EMAIL_REDIRECT_URL',
      ),
      'ONBOARDING_AI_DEV_CHECK_ENABLED' => const String.fromEnvironment(
        'ONBOARDING_AI_DEV_CHECK_ENABLED',
      ),
      'GEMINI_API_KEY' => const String.fromEnvironment('GEMINI_API_KEY'),
      'GEMINI_MODEL' => const String.fromEnvironment('GEMINI_MODEL'),
      'GEMINI_BASE_URL' => const String.fromEnvironment('GEMINI_BASE_URL'),
      'GEMINI_PLAN_MODEL' => const String.fromEnvironment('GEMINI_PLAN_MODEL'),
      'GEMINI_PLAN_FALLBACK_MODELS' => const String.fromEnvironment(
        'GEMINI_PLAN_FALLBACK_MODELS',
      ),
      'GEMINI_FALLBACK_MODELS' => const String.fromEnvironment(
        'GEMINI_FALLBACK_MODELS',
      ),
      'GEMINI_PLAN_OVERFLOW_MODELS' => const String.fromEnvironment(
        'GEMINI_PLAN_OVERFLOW_MODELS',
      ),
      'GEMINI_CHAT_MODEL' => const String.fromEnvironment('GEMINI_CHAT_MODEL'),
      'GEMINI_CHAT_FALLBACK_MODELS' => const String.fromEnvironment(
        'GEMINI_CHAT_FALLBACK_MODELS',
      ),
      _ => null,
    };
  }

  static String? _clean(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null || cleaned.isEmpty) return null;
    return cleaned;
  }
}
