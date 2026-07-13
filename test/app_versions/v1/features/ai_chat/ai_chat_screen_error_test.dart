import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/domain/entities/chat_message_entity.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/domain/repositories/ai_chat_repository.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/providers/ai_chat_providers.dart';

void main() {
  testWidgets('shows and dismisses AI unavailable error banner', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiChatRepositoryProvider.overrideWithValue(
            const _UnavailableAIChatRepository(),
          ),
        ],
        child: const MaterialApp(home: AIChatScreen()),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Nabi ơi');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

    expect(find.text(AIChatUnavailableException.message), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);

    await tester.tap(find.byTooltip('Đóng thông báo'));
    await tester.pumpAndSettle();

    expect(find.text(AIChatUnavailableException.message), findsNothing);

    await tester.pump(const Duration(seconds: 2));
  });
}

class _UnavailableAIChatRepository implements AIChatRepository {
  const _UnavailableAIChatRepository();

  @override
  Future<void> clearHistory() async {}

  @override
  Future<List<ChatMessageEntity>> getChatHistory() async => const [];

  @override
  Future<ChatMessageEntity> sendMessage(String message) {
    throw const AIChatUnavailableException();
  }
}
