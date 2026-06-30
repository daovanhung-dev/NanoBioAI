import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/services/supabase/usage_quota/usage_quota_gateway.dart';

import '../../../services/ai/ai_chat_service.dart';
import '../domain/repositories/ai_chat_repository.dart';
import '../domain/repositories/ai_chat_repository_impl.dart';

final aiChatRepositoryProvider = Provider<AIChatRepository>((ref) {
  final service = ref.watch(aiChatServiceProvider);
  return AIChatRepositoryImpl(
    aiChatService: service,
    quotaGateway: const TrustedBackendUsageQuotaGateway(),
  );
});
