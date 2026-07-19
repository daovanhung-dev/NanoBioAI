import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/domain/entities/chat_message_entity.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/domain/repositories/ai_chat_repository.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/domain/repositories/ai_chat_repository_impl.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_chat_service.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_exceptions.dart';
import 'package:nano_app/services/supabase/usage_quota/usage_quota_gateway.dart';

void main() {
  group('AIChatRepository quota gate', () {
    test('blocks before AI call when quota is denied', () async {
      final aiService = _RecordingAIChatService();
      final quotaGateway = _RecordingUsageQuotaGateway(allowed: false);
      final repository = AIChatRepositoryImpl(
        aiChatService: aiService,
        quotaGateway: quotaGateway,
      );

      await expectLater(
        repository.sendMessage('Nabi ơi, hôm nay tôi nên ăn gì?'),
        throwsA(isA<UsageQuotaExceededException>()),
      );

      expect(quotaGateway.checkCalls, 1);
      expect(quotaGateway.commitCalls, 0);
      expect(aiService.sendCalls, 0);
      expect(await repository.getChatHistory(), isEmpty);
    });

    test('commits quota only after AI response succeeds', () async {
      final aiService = _RecordingAIChatService();
      final quotaGateway = _RecordingUsageQuotaGateway();
      final repository = AIChatRepositoryImpl(
        aiChatService: aiService,
        quotaGateway: quotaGateway,
      );

      final message = await repository.sendMessage('Tôi hơi mệt');

      expect(message.content, contains('Nabi'));
      expect(quotaGateway.checkCalls, 1);
      expect(quotaGateway.commitCalls, 1);
      expect(aiService.sendCalls, 1);
      expect(aiService.acceptedTurns, 1);
      expect(await repository.getChatHistory(), hasLength(2));
    });

    test('does not commit quota when AI response fails', () async {
      final aiService = _RecordingAIChatService(shouldFail: true);
      final quotaGateway = _RecordingUsageQuotaGateway();
      final repository = AIChatRepositoryImpl(
        aiChatService: aiService,
        quotaGateway: quotaGateway,
      );

      await expectLater(
        repository.sendMessage('Tôi cần hỗ trợ'),
        throwsA(isA<AIChatUnavailableException>()),
      );

      expect(quotaGateway.checkCalls, 1);
      expect(quotaGateway.commitCalls, 0);
      expect(aiService.sendCalls, 1);
      expect(aiService.acceptedTurns, 0);
      final history = await repository.getChatHistory();
      expect(history, hasLength(1));
      expect(history.single.role, MessageRole.user);
    });

    test('maps missing configuration and does not commit quota', () async {
      final aiService = _RecordingAIChatService(configurationUnavailable: true);
      final quotaGateway = _RecordingUsageQuotaGateway();
      final repository = AIChatRepositoryImpl(
        aiChatService: aiService,
        quotaGateway: quotaGateway,
      );

      await expectLater(
        repository.sendMessage('Tôi cần hỗ trợ'),
        throwsA(isA<AIConfigurationUnavailableException>()),
      );

      expect(quotaGateway.checkCalls, 1);
      expect(quotaGateway.commitCalls, 0);
      expect(aiService.sendCalls, 1);
    });

    test('preserves Gemini authentication failure without an answer', () async {
      final quotaGateway = _RecordingUsageQuotaGateway();
      final repository = AIChatRepositoryImpl(
        aiChatService: _RecordingAIChatService(
          failure: const AIAuthenticationException(),
        ),
        quotaGateway: quotaGateway,
      );

      await expectLater(
        repository.sendMessage('Tôi cần hỗ trợ'),
        throwsA(isA<AIAuthenticationException>()),
      );

      expect(quotaGateway.commitCalls, 0);
      expect(await repository.getChatHistory(), hasLength(1));
    });

    test(
      'preserves overload and invalid-response failures without an answer',
      () async {
        for (final failure in <Object>[
          const AIOverloadedException(),
          const AIResponseInvalidException(),
        ]) {
          final quotaGateway = _RecordingUsageQuotaGateway();
          final repository = AIChatRepositoryImpl(
            aiChatService: _RecordingAIChatService(failure: failure),
            quotaGateway: quotaGateway,
          );

          Object? captured;
          try {
            await repository.sendMessage('Tôi cần hỗ trợ');
          } catch (error) {
            captured = error;
          }

          expect(captured, same(failure));
          expect(quotaGateway.commitCalls, 0);
          expect(await repository.getChatHistory(), hasLength(1));
        }
      },
    );

    test(
      'retries quota commit at most three times with one request id',
      () async {
        final quotaGateway = _RecordingUsageQuotaGateway(failCommitAttempts: 2);
        final repository = AIChatRepositoryImpl(
          aiChatService: _RecordingAIChatService(),
          quotaGateway: quotaGateway,
          requestIdFactory: (_) => 'stable-request',
          delay: (_) async {},
        );

        final response = await repository.sendMessage('Tôi cần một gợi ý');

        expect(response.role, MessageRole.assistant);
        expect(quotaGateway.commitCalls, 3);
        expect(quotaGateway.commitRequestIds, [
          'stable-request',
          'stable-request',
          'stable-request',
        ]);
      },
    );

    test('commit failure is fail-closed and adds no AI answer', () async {
      final quotaGateway = _RecordingUsageQuotaGateway(failCommitAttempts: 3);
      final aiService = _RecordingAIChatService();
      final repository = AIChatRepositoryImpl(
        aiChatService: aiService,
        quotaGateway: quotaGateway,
        requestIdFactory: (_) => 'failed-commit-request',
        delay: (_) async {},
      );

      await expectLater(
        repository.sendMessage('Tôi cần một gợi ý'),
        throwsA(isA<UsageQuotaUnavailableException>()),
      );

      expect(quotaGateway.commitCalls, 3);
      expect(aiService.acceptedTurns, 0);
      final history = await repository.getChatHistory();
      expect(history, hasLength(1));
      expect(history.single.role, MessageRole.user);
    });
  });
}

class _RecordingAIChatService extends AIChatService {
  final bool shouldFail;
  final bool configurationUnavailable;
  final Object? failure;
  int sendCalls = 0;
  int acceptedTurns = 0;

  _RecordingAIChatService({
    this.shouldFail = false,
    this.configurationUnavailable = false,
    this.failure,
  }) : super(
         textGenerator: ({required modelName, required message}) async => '',
       );

  @override
  Future<AIChatPreparedResponse> prepareMessage(String message) async {
    sendCalls++;
    final failure = this.failure;
    if (failure != null) throw failure;
    if (configurationUnavailable) {
      throw const AIConfigurationUnavailableException();
    }
    if (shouldFail) throw StateError('AI chat failed');
    return AIChatPreparedResponse(
      text: 'Nabi đã nghe bạn và sẽ gợi ý nhẹ nhàng.',
      onAccepted: () => acceptedTurns++,
    );
  }
}

class _RecordingUsageQuotaGateway implements UsageQuotaGateway {
  final bool allowed;
  final int failCommitAttempts;
  int checkCalls = 0;
  int commitCalls = 0;
  final List<String> commitRequestIds = [];

  _RecordingUsageQuotaGateway({
    this.allowed = true,
    this.failCommitAttempts = 0,
  });

  @override
  Future<UsageQuotaDecision> checkCurrentUserQuota({
    required String featureKey,
    required String requestId,
    DateTime? at,
  }) async {
    checkCalls++;
    if (allowed) return const UsageQuotaDecision.allowed();
    throw const UsageQuotaExceededException(
      UsageQuotaDecision.denied(reasonCode: 'quota_exceeded'),
    );
  }

  @override
  Future<void> commitCurrentUserQuota({
    required String featureKey,
    required String requestId,
    DateTime? at,
  }) async {
    commitCalls++;
    commitRequestIds.add(requestId);
    if (commitCalls <= failCommitAttempts) {
      throw StateError('quota commit unavailable');
    }
  }
}
