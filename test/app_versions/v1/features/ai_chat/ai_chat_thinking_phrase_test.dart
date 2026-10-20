import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/domain/entities/ai_chat_stream_event.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/domain/entities/chat_message_entity.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/domain/repositories/ai_chat_repository.dart'
    show
        AIChatRepository,
        AIChatStreamingCapability,
        AIChatUnavailableException;
import 'package:nano_app/app_versions/v1/features/ai_chat/presentation/controllers/ai_chat_controller.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/presentation/ai_chat_thinking_phrases.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/presentation/pages/ai_chat_screen.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/providers/ai_chat_providers.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPrefs.clearAll();
  });

  group('AI chat thinking phrases', () {
    test('contains 100 unique phrases and starts with the requested copy', () {
      expect(AIChatThinkingPhrases.values, hasLength(100));
      expect(AIChatThinkingPhrases.values.toSet(), hasLength(100));
      expect(
        AIChatThinkingPhrases.values.first,
        'Nabi đang suy nghĩ thật kỹ để đưa ra câu trả lời phù hợp nhất.',
      );
    });

    test('persists its cursor and wraps from phrase 100 to phrase 1', () async {
      final indices = <int>[];
      for (var index = 0; index < 101; index++) {
        indices.add(
          await AppPrefs.reserveNextAiChatThinkingPhraseIndex(
            phraseCount: AIChatThinkingPhrases.values.length,
          ),
        );
      }

      expect(indices, List<int>.generate(100, (index) => index)..add(0));
      expect(
        await AppPrefs.reserveNextAiChatThinkingPhraseIndex(
          phraseCount: AIChatThinkingPhrases.values.length,
        ),
        1,
      );
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getInt('ai_chat_thinking_phrase_next_index'), 2);
    });

    test(
      'serializes concurrent reservations without duplicate indices',
      () async {
        final indices = await Future.wait(
          List<Future<int>>.generate(
            100,
            (_) => AppPrefs.reserveNextAiChatThinkingPhraseIndex(
              phraseCount: AIChatThinkingPhrases.values.length,
            ),
          ),
        );

        expect(indices, List<int>.generate(100, (index) => index));
      },
    );

    test(
      'retry reuses its phrase and a new send advances after chat clear',
      () async {
        final repository = _ControlledAIChatRepository();
        final container = ProviderContainer(
          overrides: [aiChatRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);
        addTearDown(repository.closeStreams);
        final subscription = container.listen(
          aiChatControllerProvider,
          (_, _) {},
        );
        addTearDown(subscription.close);
        final controller = container.read(aiChatControllerProvider.notifier);

        await controller.sendMessage('   ');
        expect(repository.streams, isEmpty);

        final firstSend = controller.sendMessage('Câu hỏi đầu tiên');
        await _waitForRequest(repository, 1);
        expect(
          container.read(aiChatControllerProvider).thinkingPhrase,
          AIChatThinkingPhrases.values[0],
        );
        await controller.sendMessage('Bỏ qua khi đang xử lý');
        expect(repository.streams, hasLength(1));

        repository.streams[0].addError(const AIChatUnavailableException());
        await firstSend;
        expect(
          container.read(aiChatControllerProvider).thinkingPhrase,
          AIChatThinkingPhrases.values[0],
        );

        final retry = controller.retryLastMessage();
        await _waitForRequest(repository, 2);
        expect(
          container.read(aiChatControllerProvider).thinkingPhrase,
          AIChatThinkingPhrases.values[0],
        );
        repository.streams[1].add(
          const AIChatStreamEvent.completed(
            fullText: 'Nabi đã nhận được câu hỏi.',
          ),
        );
        await repository.streams[1].close();
        await retry;
        expect(container.read(aiChatControllerProvider).thinkingPhrase, isNull);

        await controller.clearChat();
        final nextSend = controller.sendMessage('Câu hỏi tiếp theo');
        await _waitForRequest(repository, 3);
        expect(
          container.read(aiChatControllerProvider).thinkingPhrase,
          AIChatThinkingPhrases.values[1],
        );
        repository.streams[2].addError(const AIChatUnavailableException());
        await nextSend;
      },
    );

    testWidgets('shows the selected phrase until the first streamed token', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _ControlledAIChatRepository();
      addTearDown(repository.closeStreams);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [aiChatRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.7)),
              child: const AIChatScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Câu hỏi thử nghiệm');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AIChatScreen)),
      );
      for (
        var attempt = 0;
        attempt < 10 &&
            container.read(aiChatControllerProvider).thinkingPhrase == null;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      expect(find.text(AIChatThinkingPhrases.values.first), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(repository.streams, hasLength(1));

      repository.streams.single.add(
        const AIChatStreamEvent.delta(
          delta: 'Nabi đang cân nhắc.',
          fullText: 'Nabi đang cân nhắc.',
        ),
      );
      await tester.pump();
      expect(find.text(AIChatThinkingPhrases.values.first), findsNothing);
      expect(find.text('Nabi đang cân nhắc.'), findsOneWidget);
      expect(tester.takeException(), isNull);

      repository.streams.single.add(
        const AIChatStreamEvent.completed(fullText: 'Nabi đang cân nhắc.'),
      );
      await repository.streams.single.close();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2500));
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _waitForRequest(
  _ControlledAIChatRepository repository,
  int count,
) async {
  for (
    var attempt = 0;
    attempt < 10 && repository.streams.length < count;
    attempt++
  ) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(repository.streams, hasLength(count));
}

class _ControlledAIChatRepository
    implements AIChatRepository, AIChatStreamingCapability {
  final List<StreamController<AIChatStreamEvent>> streams = [];

  @override
  Stream<AIChatStreamEvent> sendRealtimeMessageStream(String message) {
    final controller = StreamController<AIChatStreamEvent>();
    streams.add(controller);
    return controller.stream;
  }

  @override
  Future<ChatMessageEntity> sendMessage(String message) {
    throw UnsupportedError('The chat controller should use streaming.');
  }

  @override
  Future<List<ChatMessageEntity>> getChatHistory() async => const [];

  @override
  Future<void> clearHistory() async {}

  Future<void> closeStreams() async {
    for (final stream in streams) {
      if (!stream.isClosed) await stream.close();
    }
  }
}
