abstract class SpeechRecognitionGateway {
  Future<bool> initialize();

  Future<String> listenOnce({
    String localeId = 'vi_VN',
    Duration listenFor = const Duration(minutes: 3),
    Duration pauseFor = const Duration(seconds: 1),
  });

  Future<void> stop();

  Future<void> cancel();
}

abstract class TextToSpeechGateway {
  Future<void> initialize();

  /// Completes only after the utterance has finished or failed.
  Future<void> speak(String text);

  Future<void> stop();
}

class SpeechRecognitionUnavailableException implements Exception {
  final String? message;

  const SpeechRecognitionUnavailableException({this.message});

  @override
  String toString() => message ?? 'Speech recognition unavailable';
}

class SpeechRecognitionPermissionDeniedException implements Exception {
  final bool permanentlyDenied;

  const SpeechRecognitionPermissionDeniedException({
    this.permanentlyDenied = false,
  });
}
