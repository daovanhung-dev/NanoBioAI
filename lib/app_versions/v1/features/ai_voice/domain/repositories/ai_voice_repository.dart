abstract class AiVoiceRepository {
  Future<String> sendTurn(String message);

  /// Clears the in-memory conversation. Voice history is never persisted.
  void resetSession();
}
