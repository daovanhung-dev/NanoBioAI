import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/config/app_env.dart';

const _dartDefinedApiBaseUrl = String.fromEnvironment('API_BASE_URL');

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

  test(
    'dart-define takes precedence over dotenv and bundled configuration',
    () async {
      expect(_dartDefinedApiBaseUrl, isNotEmpty);
      await AppEnv.loadOptionalDotEnv(fileName: 'missing.env');
      dotenv.loadFromString(envString: 'API_BASE_URL=http://10.0.2.2:8000');

      expect(AppEnv.maybeString('API_BASE_URL'), _dartDefinedApiBaseUrl);
      expect(AppEnv.valueSource('API_BASE_URL'), AppEnvValueSource.dartDefine);
    },
  );
}
