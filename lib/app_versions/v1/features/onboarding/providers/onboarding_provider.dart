import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_service.dart';
import 'package:nano_app/core/config/app_env.dart';

import '../presentation/controllers/onboarding_controller.dart';

final onboardingProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );

final onboardingAiDevCheckEnabledProvider = Provider<bool>((ref) {
  return AppEnv.boolValue(
    'ONBOARDING_AI_DEV_CHECK_ENABLED',
    defaultValue: false,
  );
});

final onboardingAiDevCheckProvider = FutureProvider<AIConnectionCheckResult?>((
  ref,
) async {
  final enabled = ref.watch(onboardingAiDevCheckEnabledProvider);
  if (!enabled) {
    return null;
  }

  try {
    return await ref.read(aiServiceProvider).checkConnection();
  } catch (error) {
    return AIConnectionCheckResult.failure(
      message: _sanitizeAiDevCheckError(error),
    );
  }
});

String _sanitizeAiDevCheckError(Object error) {
  final text = error
      .toString()
      .replaceAll(RegExp(r'AIza[0-9A-Za-z\-_]{20,}'), '***')
      .replaceAll(RegExp(r'sk-[A-Za-z0-9_\-]{20,}'), '***');

  if (text.contains('GEMINI_API_KEY')) {
    return 'Thiếu GEMINI_API_KEY hoặc key đang rỗng.';
  }

  if (text.length > 180) {
    return 'Không thể kiểm tra kết nối AI. Kiểm tra cấu hình env, model hoặc mạng.';
  }

  return 'Không thể kiểm tra kết nối AI: $text';
}
