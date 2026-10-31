import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/config/app_env.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.clean();
    AppEnv.clearBundledAuthConfigForTesting();
  });

  tearDown(() {
    dotenv.clean();
    AppEnv.clearBundledAuthConfigForTesting();
  });

  group('AppEnv', () {
    test('reads optional app values from dotenv fallback', () {
      dotenv.loadFromString(
        envString: [
          'ACCOUNT_DELETION_URL=https://example.test/delete',
          'FEATURE_FLAG=false',
        ].join('\n'),
      );

      expect(
        AppEnv.maybeString('ACCOUNT_DELETION_URL'),
        'https://example.test/delete',
      );
      expect(
        AppEnv.valueSource('ACCOUNT_DELETION_URL'),
        AppEnvValueSource.dotEnv,
      );
      expect(AppEnv.boolValue('FEATURE_FLAG', defaultValue: true), isFalse);
    });

    test('keeps optional loading safe when both files are missing', () async {
      await AppEnv.loadOptionalDotEnv(
        fileName: 'missing.env',
        bundledAuthFileName: 'missing-auth.env',
      );

      expect(AppEnv.maybeString('UNKNOWN_KEY'), isNull);
      expect(AppEnv.valueSource('UNKNOWN_KEY'), AppEnvValueSource.missing);
      expect(AppEnv.maybeString('API_BASE_URL'), isNull);
    });

    test('loads bundled backend origin for a plain app build', () async {
      await AppEnv.loadOptionalDotEnv(fileName: 'missing.env');

      final apiBaseUrl = AppEnv.maybeString('API_BASE_URL');
      expect(apiBaseUrl, isNotNull);
      expect(Uri.parse(apiBaseUrl!).scheme, 'https');
      expect(Uri.parse(apiBaseUrl).host, '42.118.174.147');
      expect(AppEnv.maybeString('GEMINI_API_KEY'), isNull);
      expect(AppEnv.valueSource('GEMINI_API_KEY'), AppEnvValueSource.missing);
    });

    test('returns no backend origin when it is missing', () {
      dotenv.loadFromString(envString: 'UNRELATED=https://example.test');

      expect(AppEnv.maybeString('API_BASE_URL'), isNull);
    });

    test('reads backend origin from dotenv', () {
      dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');

      expect(AppEnv.maybeString('API_BASE_URL'), 'https://api.example.test');
    });

    test('throws a safe message for missing required config', () {
      expect(
        () => AppEnv.requiredString('API_BASE_URL'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('API_BASE_URL'),
          ),
        ),
      );
    });
  });
}
