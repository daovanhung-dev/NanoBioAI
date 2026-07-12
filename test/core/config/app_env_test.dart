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
    test('reads optional values from dotenv fallback', () {
      dotenv.loadFromString(
        envString: [
          'AUTH_DELETE_ACCOUNT_FUNCTION=delete-account-dev',
          'AUTH_CONFIRM_EMAIL_REQUIRED=false',
        ].join('\n'),
      );

      expect(
        AppEnv.maybeString('AUTH_DELETE_ACCOUNT_FUNCTION'),
        'delete-account-dev',
      );
      expect(
        AppEnv.boolValue('AUTH_CONFIRM_EMAIL_REQUIRED', defaultValue: true),
        isFalse,
      );
    });

    test('keeps optional loading safe when both files are missing', () async {
      await AppEnv.loadOptionalDotEnv(
        fileName: 'missing.env',
        bundledAuthFileName: 'missing-auth.env',
      );

      expect(AppEnv.maybeString('UNKNOWN_KEY'), isNull);
      expect(AppEnv.maybeSupabaseConfig(), isNull);
    });

    test('loads bundled public Supabase config for a plain app build', () async {
      await AppEnv.loadOptionalDotEnv(fileName: 'missing.env');

      final config = AppEnv.maybeSupabaseConfig();
      expect(config, isNotNull);
      final resolvedConfig = config!;
      expect(Uri.parse(resolvedConfig.url).scheme, 'https');
      expect(Uri.parse(resolvedConfig.url).host, endsWith('.supabase.co'));
      expect(resolvedConfig.anonKey, isNotEmpty);
      expect(
        AppEnv.maybeString('AUTH_EMAIL_REDIRECT_URL'),
        isNotEmpty,
      );
      expect(AppEnv.maybeString('GEMINI_API_KEY'), isNull);
    });

    test('returns no Supabase config when url or anon key is missing', () {
      dotenv.loadFromString(envString: 'SUPABASE_URL=https://example.test');

      expect(AppEnv.maybeSupabaseConfig(), isNull);
    });

    test('returns Supabase config when both values are present', () {
      dotenv.loadFromString(
        envString: [
          'SUPABASE_URL=https://example.test',
          'SUPABASE_ANON_KEY=anon-key',
        ].join('\n'),
      );

      expect(AppEnv.maybeSupabaseConfig(), (
        url: 'https://example.test',
        anonKey: 'anon-key',
      ));
    });

    test('throws a safe message for missing required config', () {
      expect(
        () => AppEnv.requiredString('SUPABASE_URL'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('SUPABASE_URL'),
          ),
        ),
      );
    });
  });
}
