enum VoiceChatFailure {
  invalidRequest,
  temporarilyUnavailable,
  invalidResponse,
  unavailable,
}

class VoiceChatException implements Exception {
  final VoiceChatFailure failure;

  const VoiceChatException(this.failure);

  @override
  String toString() => 'VoiceChatException(${failure.name})';
}
