enum VoiceChatFailure {
  invalidRequest,
  temporarilyUnavailable,
  invalidResponse,
  unavailable,
  authenticationRequired,
  unsupportedPlatform,
}

class VoiceChatException implements Exception {
  final VoiceChatFailure failure;

  const VoiceChatException(this.failure);

  @override
  String toString() => 'VoiceChatException(${failure.name})';
}
