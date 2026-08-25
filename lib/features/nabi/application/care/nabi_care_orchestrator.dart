import '../../domain/care/nabi_care_models.dart';
import '../../domain/care/nabi_care_repository.dart';
import 'nabi_care_ai_analyzer.dart';
import 'nabi_care_context_builder.dart';
import 'nabi_care_safety_policy.dart';
import 'nabi_care_signal_engine.dart';

class NabiCareOrchestrator {
  final NabiCareRepository repository;
  final NabiCareContextBuilder contextBuilder;
  final NabiCareSignalEngine signalEngine;
  final NabiCareAiAnalyzer aiAnalyzer;
  final NabiCareSafetyPolicy safetyPolicy;
  final DateTime Function() now;

  NabiCareOrchestrator({
    required this.repository,
    required this.aiAnalyzer,
    NabiCareContextBuilder? contextBuilder,
    NabiCareSignalEngine? signalEngine,
    NabiCareSafetyPolicy? safetyPolicy,
    DateTime Function()? now,
  })  : contextBuilder = contextBuilder ?? NabiCareContextBuilder(now: now),
        signalEngine = signalEngine ?? const NabiCareSignalEngine(),
        safetyPolicy = safetyPolicy ?? const NabiCareSafetyPolicy(),
        now = now ?? DateTime.now;

  Future<NabiCareResult> evaluate({
    String? subjectId,
    required NabiCareTrigger trigger,
    bool force = false,
  }) async {
    final raw = await repository.loadRawContext(subjectId: subjectId);
    final baseSnapshot = contextBuilder.build(raw);
    final signals = signalEngine.evaluate(baseSnapshot);
    final snapshot = baseSnapshot.withSignals(signals);
    final fingerprint = snapshot.fingerprint();

    if (!force && !_alwaysReevaluate(trigger)) {
      final cached =
          await repository.loadLatestCachedAnalysis(snapshot.actorKey);
      if (cached != null &&
          cached.fingerprint == fingerprint &&
          now().isBefore(cached.analysis.nextReviewAt)) {
        return NabiCareResult(
          snapshot: snapshot,
          analysis: cached.analysis,
          fingerprint: fingerprint,
          fromCache: true,
        );
      }
    }

    final rawAnalysis = await aiAnalyzer.analyze(snapshot);
    final safeAnalysis = safetyPolicy.apply(rawAnalysis, snapshot);

    await repository.saveAnalysis(
      actorKey: snapshot.actorKey,
      fingerprint: fingerprint,
      analysis: safeAnalysis,
    );

    return NabiCareResult(
      snapshot: snapshot,
      analysis: safeAnalysis,
      fingerprint: fingerprint,
    );
  }

  Future<void> feedback({
    required NabiCareResult result,
    required NabiCareFeedbackType feedback,
    String? actionId,
  }) {
    return repository.saveFeedback(
      actorKey: result.snapshot.actorKey,
      fingerprint: result.fingerprint,
      feedback: feedback,
      actionId: actionId,
    );
  }

  bool _alwaysReevaluate(NabiCareTrigger trigger) {
    return switch (trigger) {
      NabiCareTrigger.symptomChanged ||
      NabiCareTrigger.medicationChanged ||
      NabiCareTrigger.labChanged ||
      NabiCareTrigger.manualReview => true,
      _ => false,
    };
  }
}
