import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_text_client.dart';
import 'package:nano_app/core/ai_local/local_ai_text_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'missing selected model is reported without a remote fallback',
    () async {
      SharedPreferences.setMockInitialValues({});

      await expectLater(
        const LocalAiTextClient().generateText(
          model: LocalAiTextClient.modelId,
          messages: const [AiMessage.user('Xin chào')],
          generationConfig: const AiGenerationConfig(),
        ),
        throwsA(
          isA<AiInferenceException>().having(
            (error) => error.status,
            'status',
            'local_model_not_ready',
          ),
        ),
      );
    },
  );
}
