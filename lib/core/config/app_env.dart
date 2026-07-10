import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  AppEnv._();

  static Future<void> loadOptionalDotEnv({String fileName = '.env'}) async {
    try {
      await dotenv.load(fileName: fileName, isOptional: true);
    } catch (_) {
      // `.env` is intentionally not a bundled asset. Local legacy setups may
      // still provide it; production configuration should use --dart-define.
    }
  }

  static String requiredString(String key) {
    final value = maybeString(key);
    if (value != null) return value;
    throw StateError(
      'Missing required app configuration: $key. '
      'Provide it via --dart-define or local dotenv fallback.',
    );
  }

  static String? maybeString(String key) {
    return _clean(_fromDartDefine(key)) ?? _clean(_fromDotEnv(key));
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
