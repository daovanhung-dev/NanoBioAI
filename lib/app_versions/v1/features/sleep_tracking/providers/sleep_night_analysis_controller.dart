import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';

import '../domain/entities/sleep_morning_checkin.dart';
import '../domain/entities/sleep_night_analysis.dart';
import '../domain/entities/sleep_safety_event.dart';
import '../domain/entities/sleep_safety_session.dart';
import '../domain/services/sleep_night_analysis_service.dart';
import 'sleep_analysis_dependencies.dart';
import 'sleep_safety_providers.dart';

class SleepNightAnalysisViewState {
  const SleepNightAnalysisViewState({
    this.session,
    this.events = const [],
    this.analysis,
    this.loading = false,
    this.generatingAi = false,
    this.aiConfigured = false,
    this.errorMessage,
  });

  final SleepSafetySession? session;
  final List<SleepSafetyEvent> events;
  final SleepNightAnalysis? analysis;
  final bool loading;
  final bool generatingAi;
  final bool aiConfigured;
  final String? errorMessage;

  SleepNightAnalysisViewState copyWith({
    SleepSafetySession? session,
    List<SleepSafetyEvent>? events,
    SleepNightAnalysis? analysis,
    bool? loading,
    bool? generatingAi,
    bool? aiConfigured,
    String? errorMessage,
    bool clearError = false,
  }) => SleepNightAnalysisViewState(
    session: session ?? this.session,
    events: events ?? this.events,
    analysis: analysis ?? this.analysis,
    loading: loading ?? this.loading,
    generatingAi: generatingAi ?? this.generatingAi,
    aiConfigured: aiConfigured ?? this.aiConfigured,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}

class SleepNightAnalysisController extends Notifier<SleepNightAnalysisViewState> {
  @override
  SleepNightAnalysisViewState build() {
    ref.watch(currentAuthUserIdProvider);
    final ai = ref.watch(sleepAnalysisAIServiceProvider);
    return SleepNightAnalysisViewState(aiConfigured: ai.isConfigured);
  }

  Future<void> load(String sessionId, {SleepMorningCheckin? checkinOverride}) async {
    if (state.loading) return;
    final aiConfigured = ref.read(sleepAnalysisAIServiceProvider).isConfigured;
    state = SleepNightAnalysisViewState(loading: true, aiConfigured: aiConfigured);
    final repository = ref.read(sleepSafetyRepositoryProvider);
    final calculator = ref.read(sleepNightAnalysisServiceProvider);
    try {
      final session = await repository.getSession(sessionId);
      final currentUserId = ref.read(currentAuthUserIdProvider);
      if (session == null ||
          currentUserId == null ||
          session.userId != currentUserId ||
          session.endedAt == null) {
        throw StateError('sleep_session_not_found');
      }
      final events = await repository.listEventsForSession(sessionId);
      final cached = await repository.getNightAnalysis(sessionId);
      final sessions = await repository.listSessions(session.userId, limit: 7);
      final previous = <SleepNightInput>[];
      for (final item in sessions) {
        if (item.id == sessionId) continue;
        previous.add(
          SleepNightInput(
            session: item,
            events: await repository.listEventsForSession(item.id),
          ),
        );
      }
      final calculated = calculator.calculate(
        session: session,
        events: events,
        previousNights: previous,
        morningCheckin: checkinOverride ?? cached?.morningCheckin,
      );
      final merged = SleepNightAnalysis(
        sessionId: calculated.sessionId,
        userId: calculated.userId,
        formulaVersion: calculated.formulaVersion,
        startedAt: calculated.startedAt,
        endedAt: calculated.endedAt,
        metrics: calculated.metrics,
        eventDistribution: calculated.eventDistribution,
        trend: calculated.trend,
        dataQualityScore: calculated.dataQualityScore,
        safetyAttentionScore: calculated.safetyAttentionScore,
        sleepWellnessScore: calculated.sleepWellnessScore,
        morningCheckin: calculated.morningCheckin,
        aiAnalysisJson: cached?.formulaVersion == calculated.formulaVersion ? cached?.aiAnalysisJson : null,
        aiModel: cached?.formulaVersion == calculated.formulaVersion ? cached?.aiModel : null,
        aiGeneratedAt: cached?.formulaVersion == calculated.formulaVersion ? cached?.aiGeneratedAt : null,
        aiRequestFingerprint: cached?.formulaVersion == calculated.formulaVersion ? cached?.aiRequestFingerprint : null,
        createdAt: cached?.createdAt ?? calculated.createdAt,
        updatedAt: calculated.updatedAt,
      );
      await repository.saveNightAnalysis(merged);
      state = state.copyWith(
        session: session,
        events: events,
        analysis: merged,
        loading: false,
        aiConfigured: ref.read(sleepAnalysisAIServiceProvider).isConfigured,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'Nabi chưa tạo được phân tích cho phiên này. Bạn thử lại nhé.',
      );
    }
  }

  Future<void> saveMorningCheckin(SleepMorningCheckin checkin) async {
    final sessionId = state.session?.id;
    if (sessionId == null) return;
    await load(sessionId, checkinOverride: checkin);
  }

  Future<void> generateAiAnalysis() async {
    final analysis = state.analysis;
    if (analysis == null || state.generatingAi) return;
    final ai = ref.read(sleepAnalysisAIServiceProvider);
    if (!ai.isConfigured) {
      state = state.copyWith(
        errorMessage: 'Chưa cấu hình GEMINI_API_KEY nên Nabi chỉ hiển thị phân tích cục bộ.',
      );
      return;
    }
    state = state.copyWith(generatingAi: true, clearError: true);
    try {
      final result = await ai.generate(analysis);
      final updated = analysis.copyWith(
        aiAnalysisJson: result.toJson(),
        aiModel: result.model,
        aiGeneratedAt: result.generatedAt,
        aiRequestFingerprint: _fingerprint(analysis.toSafeAiPayload()),
        updatedAt: DateTime.now(),
      );
      await ref.read(sleepSafetyRepositoryProvider).saveNightAnalysis(updated);
      state = state.copyWith(analysis: updated, generatingAi: false, clearError: true);
    } catch (_) {
      state = state.copyWith(
        generatingAi: false,
        errorMessage: 'Phân tích AI chưa hoàn tất. Phần chỉ số cục bộ vẫn dùng bình thường.',
      );
    }
  }

  String _fingerprint(Map<String, Object?> payload) {
    final bytes = utf8.encode(jsonEncode(payload));
    var hash = 0x811c9dc5;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
