import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/care/nabi_care_repository_impl.dart';
import '../../data/nabi_feature_flags.dart';
import '../../domain/care/nabi_care_models.dart';
import '../../domain/care/nabi_care_repository.dart';
import 'nabi_care_ai_analyzer.dart';
import 'nabi_care_orchestrator.dart';
import 'package:nano_app/app_versions/v1/services/ai/nabi_care_ai_gateway.dart';

enum NabiCareLoadStatus { idle, loading, ready, error }

class NabiCareState {
  final NabiCareLoadStatus status;
  final NabiCareResult? result;
  final String? errorCode;
  final NabiCareFeedbackType? lastFeedback;

  const NabiCareState({
    this.status = NabiCareLoadStatus.idle,
    this.result,
    this.errorCode,
    this.lastFeedback,
  });

  NabiCareState copyWith({
    NabiCareLoadStatus? status,
    NabiCareResult? result,
    String? errorCode,
    NabiCareFeedbackType? lastFeedback,
    bool clearError = false,
  }) {
    return NabiCareState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorCode: clearError ? null : errorCode ?? this.errorCode,
      lastFeedback: lastFeedback ?? this.lastFeedback,
    );
  }
}

final nabiCareRepositoryProvider = Provider<NabiCareRepository>(
  (_) => SqliteNabiCareRepository(),
);

final nabiCareAiGatewayProvider = Provider<NabiCareAiGateway>(
  (_) => GeminiNabiCareAiGateway(),
);

final nabiCareOrchestratorProvider = Provider<NabiCareOrchestrator>((ref) {
  final gateway = ref.watch(nabiCareAiGatewayProvider);
  return NabiCareOrchestrator(
    repository: ref.watch(nabiCareRepositoryProvider),
    aiAnalyzer: NabiCareAiAnalyzer(gateway: gateway),
  );
});

final nabiCareControllerProvider =
    NotifierProvider<NabiCareController, NabiCareState>(NabiCareController.new);

class NabiCareController extends Notifier<NabiCareState> {
  @override
  NabiCareState build() => const NabiCareState();

  Future<NabiCareResult?> refresh({
    NabiCareTrigger trigger = NabiCareTrigger.appOpen,
    String? subjectId,
    bool force = false,
  }) async {
    if (!NabiFeatureFlags.aiCareEnabled && !force) {
      return state.result;
    }
    if (state.status == NabiCareLoadStatus.loading) {
      return state.result;
    }

    state = state.copyWith(
      status: NabiCareLoadStatus.loading,
      clearError: true,
    );

    try {
      final result = await ref
          .read(nabiCareOrchestratorProvider)
          .evaluate(subjectId: subjectId, trigger: trigger, force: force);
      state = NabiCareState(status: NabiCareLoadStatus.ready, result: result);
      return result;
    } catch (_) {
      state = state.copyWith(
        status: NabiCareLoadStatus.error,
        errorCode: 'care_analysis_failed',
      );
      return null;
    }
  }

  Future<void> sendFeedback(
    NabiCareFeedbackType feedback, {
    String? actionId,
  }) async {
    final result = state.result;
    if (result == null) return;

    try {
      await ref
          .read(nabiCareOrchestratorProvider)
          .feedback(result: result, feedback: feedback, actionId: actionId);
      state = state.copyWith(lastFeedback: feedback);
    } catch (_) {
      state = state.copyWith(errorCode: 'care_feedback_failed');
    }
  }
}
