import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/domain/entities/chat_message_entity.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/domain/repositories/ai_chat_repository.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/providers/ai_chat_providers.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/domain/entities/ai_content_report.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/domain/repositories/ai_content_report_repository.dart';

void main() {
  testWidgets('assistant messages expose reporting, user messages do not', (
    tester,
  ) async {
    final reports = _FakeReportRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiChatRepositoryProvider.overrideWithValue(
            const _HistoryRepository(),
          ),
          aiContentReportRepositoryProvider.overrideWithValue(reports),
        ],
        child: const MaterialApp(home: AIChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Báo cáo phản hồi này'), findsOneWidget);
    expect(find.text('Báo cáo'), findsOneWidget);
  });

  testWidgets('report sheet requires a reason and persists a guest report', (
    tester,
  ) async {
    final reports = _FakeReportRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiChatRepositoryProvider.overrideWithValue(
            const _HistoryRepository(),
          ),
          aiContentReportRepositoryProvider.overrideWithValue(reports),
        ],
        child: const MaterialApp(home: AIChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Báo cáo phản hồi này'));
    await tester.pumpAndSettle();
    expect(find.text('Báo cáo phản hồi này'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Gửi báo cáo'),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Có thể gây hại hoặc không an toàn'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Gửi báo cáo'));
    await tester.pumpAndSettle();

    expect(reports.lastReport?.reason, AiContentReportReason.unsafe);
    expect(find.text('Cảm ơn bạn đã giúp Nabi cải thiện.'), findsOneWidget);
  });
}

class _HistoryRepository implements AIChatRepository {
  const _HistoryRepository();

  @override
  Future<void> clearHistory() async {}

  @override
  Future<List<ChatMessageEntity>> getChatHistory() async => [
    ChatMessageEntity(
      id: 'user-1',
      content: 'Tôi hơi mệt',
      role: MessageRole.user,
      timestamp: DateTime(2026, 8, 28),
    ),
    ChatMessageEntity(
      id: 'assistant-1',
      content: 'Bạn hãy nghỉ ngơi và uống đủ nước nhé.',
      role: MessageRole.assistant,
      timestamp: DateTime(2026, 8, 28),
    ),
  ];

  @override
  Future<ChatMessageEntity> sendMessage(String message) async =>
      (await getChatHistory()).last;
}

class _FakeReportRepository implements AiContentReportRepository {
  AiContentReport? lastReport;

  @override
  Future<void> submit(AiContentReport report) async => lastReport = report;
}
