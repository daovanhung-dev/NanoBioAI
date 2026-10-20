import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/domain/entities/chat_message_entity.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/domain/repositories/ai_chat_repository_impl.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/presentation/controllers/ai_chat_controller.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/providers/ai_chat_providers.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_chat_service.dart';
import 'package:nano_app/core/ai_local/local_ai_runtime_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Qwen3 1.7B answers through the local chat flow', (tester) async {
    expect(
      await LocalAiRuntimeService.instance.selectedModelId(),
      'qwen3-17b-q4',
    );

    const prompt = 'Trả lời ngắn gọn bằng tiếng Việt: hai cộng hai bằng mấy?';
    final repository = AIChatRepositoryImpl(aiChatService: AIChatService());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [aiChatRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: AIChatScreen()),
      ),
    );
    await tester.pump();

    final screenContext = tester.element(find.byType(AIChatScreen));
    final container = ProviderScope.containerOf(screenContext, listen: false);

    await tester.enterText(find.byType(TextField), prompt);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();

    final stopwatch = Stopwatch()..start();
    while (container.read(aiChatControllerProvider).isLoading &&
        stopwatch.elapsed < const Duration(minutes: 3)) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    final state = container.read(aiChatControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.messages, hasLength(2));
    expect(state.messages.last.role, MessageRole.assistant);
    expect(state.messages.last.content.trim().isNotEmpty, isTrue);

    // Let Nabi's answer-ready animation timers finish before ProviderScope is
    // disposed at the end of the widget test.
    await tester.pump(const Duration(seconds: 3));
  });
}
