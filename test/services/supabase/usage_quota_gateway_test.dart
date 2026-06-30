import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/services/supabase/usage_quota/usage_quota_gateway.dart';

void main() {
  group('TrustedBackendUsageQuotaGateway', () {
    test('checks current user quota through trusted RPC contract', () async {
      final client = _RecordingQuotaRpcClient(
        currentUserIdValue: 'user-1',
        response: [
          {
            'allowed': true,
            'used_count': 1,
            'limit_count': 3,
            'reset_at': '2026-07-01T00:00:00Z',
          },
        ],
      );
      final gateway = TrustedBackendUsageQuotaGateway(
        rpcClient: client,
        now: () => DateTime.utc(2026, 6, 30, 12),
      );

      final decision = await gateway.checkCurrentUserQuota(
        featureKey: UsageQuotaFeatureKey.aiChatMessage,
        requestId: 'chat-1',
      );

      expect(decision.allowed, isTrue);
      expect(decision.usedCount, 1);
      expect(decision.limitCount, 3);
      expect(client.calls.single.functionName, 'check_usage_quota');
      expect(client.calls.single.params['p_user_id'], 'user-1');
      expect(
        client.calls.single.params['p_feature_key'],
        UsageQuotaFeatureKey.aiChatMessage,
      );
      expect(
        client.calls.single.params['p_reset_timezone'],
        'Asia/Ho_Chi_Minh',
      );
    });

    test('commits quota only through commit RPC', () async {
      final client = _RecordingQuotaRpcClient(
        currentUserIdValue: 'user-1',
        response: {'committed': true, 'used_count': 2, 'limit_count': 3},
      );
      final gateway = TrustedBackendUsageQuotaGateway(rpcClient: client);

      await gateway.commitCurrentUserQuota(
        featureKey: UsageQuotaFeatureKey.aiChatMessage,
        requestId: 'chat-2',
        at: DateTime.utc(2026, 6, 30, 12),
      );

      expect(client.calls.single.functionName, 'commit_usage_quota');
      expect(client.calls.single.params['p_request_id'], 'chat-2');
    });

    test('throws before RPC when there is no authenticated user', () async {
      final client = _RecordingQuotaRpcClient(currentUserIdValue: null);
      final gateway = TrustedBackendUsageQuotaGateway(rpcClient: client);

      await expectLater(
        gateway.checkCurrentUserQuota(
          featureKey: UsageQuotaFeatureKey.aiChatMessage,
          requestId: 'chat-3',
        ),
        throwsA(isA<UsageQuotaAuthRequiredException>()),
      );

      expect(client.calls, isEmpty);
    });

    test('maps denied RPC response to quota exception', () async {
      final client = _RecordingQuotaRpcClient(
        currentUserIdValue: 'user-1',
        response: {
          'allowed': false,
          'used_count': 3,
          'limit_count': 3,
          'reason_code': 'quota_exceeded',
        },
      );
      final gateway = TrustedBackendUsageQuotaGateway(rpcClient: client);

      await expectLater(
        gateway.checkCurrentUserQuota(
          featureKey: UsageQuotaFeatureKey.aiChatMessage,
          requestId: 'chat-4',
        ),
        throwsA(isA<UsageQuotaExceededException>()),
      );
    });
  });
}

class _RecordingQuotaRpcClient implements UsageQuotaRpcClient {
  final String? currentUserIdValue;
  final Object? response;
  final calls = <_RpcCall>[];

  _RecordingQuotaRpcClient({required this.currentUserIdValue, this.response});

  @override
  String? get currentUserId => currentUserIdValue;

  @override
  Future<Object?> rpc(
    String functionName, {
    Map<String, Object?> params = const {},
  }) async {
    calls.add(_RpcCall(functionName, params));
    return response ?? {'allowed': true};
  }
}

class _RpcCall {
  final String functionName;
  final Map<String, Object?> params;

  const _RpcCall(this.functionName, this.params);
}
