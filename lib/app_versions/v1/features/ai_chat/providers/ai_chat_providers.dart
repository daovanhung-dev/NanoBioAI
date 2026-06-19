import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/repositories/ai_chat_repository.dart';
import '../domain/repositories/ai_chat_repository_impl.dart';
import '../../../services/ai/ai_chat_service.dart';

final aiChatRepositoryProvider = Provider<AIChatRepository>((ref) {
  final service = ref.watch(aiChatServiceProvider);
  return AIChatRepositoryImpl(aiChatService: service);
});
