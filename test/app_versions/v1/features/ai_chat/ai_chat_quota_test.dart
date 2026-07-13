import 'package:flutter_test/flutter_test.dart';
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
        throwsStateError,
      );

      expect(quotaGateway.checkCalls, 1);
      expect(quotaGateway.commitCalls, 0);
      expect(aiService.sendCalls, 1);
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
        throwsA(
          isA<AIChatUnavailableException>().having(
            (error) => error.userMessage,
            'userMessage',
            AIChatUnavailableException.message,
          ),
        ),
      );

      expect(quotaGateway.checkCalls, 1);
      expect(quotaGateway.commitCalls, 0);
      expect(aiService.sendCalls, 1);
    });
  });
}

class _RecordingAIChatService extends AIChatService {
  final bool shouldFail;
  final bool configurationUnavailable;
  int sendCalls = 0;

  _RecordingAIChatService({
    this.shouldFail = false,
    this.configurationUnavailable = false,
  }) : super(
         textGenerator: ({required modelName, required message}) async => '',
       );

  @override
  Future<String> sendMessage(String message) async {
    sendCalls++;
    if (configurationUnavailable) {
      throw const AIConfigurationUnavailableException();
    }
    if (shouldFail) throw StateError('AI chat failed');
    return 'Nabi đã nghe bạn và sẽ gợi ý nhẹ nhàng.';
  }
}

class _RecordingUsageQuotaGateway implements UsageQuotaGateway {
  final bool allowed;
  int checkCalls = 0;
  int commitCalls = 0;

  _RecordingUsageQuotaGateway({this.allowed = true});

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
  }
}
