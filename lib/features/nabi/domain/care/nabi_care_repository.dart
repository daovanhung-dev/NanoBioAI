import 'nabi_care_models.dart';

abstract interface class NabiCareAiGateway {
  Future<String> generateAnalysis({
    required Map<String, Object?> payload,
    required String systemInstruction,
  });
}

abstract interface class NabiCareRepository {
  Future<NabiCareRawContext> loadRawContext({String? subjectId});

  Future<NabiCareCachedAnalysis?> loadLatestCachedAnalysis(String actorKey);

  Future<void> saveAnalysis({
    required String actorKey,
    required String fingerprint,
    required NabiCareAnalysis analysis,
  });

  Future<void> saveFeedback({
    required String actorKey,
    required String fingerprint,
    required NabiCareFeedbackType feedback,
    String? actionId,
  });
}
