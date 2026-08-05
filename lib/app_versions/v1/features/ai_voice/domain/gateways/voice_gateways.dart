abstract class SpeechRecognitionGateway {
  Future<bool> initialize();

  Future<String> listenOnce({
    String localeId = 'vi_VN',
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 4),
  });

  Future<void> stop();

  Future<void> cancel();
}

abstract class TextToSpeechGateway {
  Future<void> initialize();

  Future<void> speak(String text);

  Future<void> stop();
}
