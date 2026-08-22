import 'dart:async';

import '../entities/speech_recognition_event.dart';

/// Backwards-compatible voice contract. Existing tests/fakes can keep
/// implementing the original one-shot methods unchanged.
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

/// Optional realtime capability implemented by the device gateway.
abstract class RealtimeSpeechRecognitionCapability {
  Future<Stream<SpeechRecognitionEvent>> startRealtimeSession({
    String localeId = 'vi_VN',
    Duration maxUtteranceDuration = const Duration(minutes: 3),
    Duration segmentDuration = const Duration(seconds: 50),
    Duration pauseFor = const Duration(milliseconds: 1300),
  });

  Future<void> finishRealtimeSession();
}

extension SpeechRecognitionRealtimeExtension on SpeechRecognitionGateway {
  Future<Stream<SpeechRecognitionEvent>> startSession({
    String localeId = 'vi_VN',
    Duration maxUtteranceDuration = const Duration(minutes: 3),
    Duration segmentDuration = const Duration(seconds: 50),
    Duration pauseFor = const Duration(milliseconds: 1300),
  }) async {
    final gateway = this;
    if (gateway is RealtimeSpeechRecognitionCapability) {
      return (gateway as RealtimeSpeechRecognitionCapability)
          .startRealtimeSession(
        localeId: localeId,
        maxUtteranceDuration: maxUtteranceDuration,
        segmentDuration: segmentDuration,
        pauseFor: pauseFor,
      );
    }

    // Compatibility fallback for old fakes/platform gateways: one recognition
    // result is adapted into the realtime event contract.
    final controller = StreamController<SpeechRecognitionEvent>();
    Future<void>(() async {
      try {
        controller.add(const SpeechRecognitionEvent.started(generation: 1));
        final result = await gateway.listenOnce(
          localeId: localeId,
          listenFor: maxUtteranceDuration,
          pauseFor: pauseFor,
        );
        if (result.trim().isNotEmpty) {
          controller.add(
            SpeechRecognitionEvent.finalSegment(
              transcript: result.trim(),
              generation: 1,
            ),
          );
        }
        controller.add(
          SpeechRecognitionEvent.completed(
            transcript: result.trim(),
            generation: 1,
          ),
        );
      } catch (error) {
        controller.add(
          SpeechRecognitionEvent.failure(error: error, generation: 1),
        );
      } finally {
        await controller.close();
      }
    });
    return controller.stream;
  }

  Future<void> finishSession() {
    final gateway = this;
    if (gateway is RealtimeSpeechRecognitionCapability) {
      return (gateway as RealtimeSpeechRecognitionCapability)
          .finishRealtimeSession();
    }
    return gateway.stop();
  }
}

abstract class TextToSpeechGateway {
  Future<void> initialize();

  Future<void> speak(String text);

  Future<void> stop();
}

abstract class RealtimeTextToSpeechCapability {
  Future<void> speakRealtimeChunk(String text);

  Future<void> stopRealtimeImmediately();
}

extension TextToSpeechRealtimeExtension on TextToSpeechGateway {
  Future<void> speakChunk(String text) {
    final gateway = this;
    if (gateway is RealtimeTextToSpeechCapability) {
      return (gateway as RealtimeTextToSpeechCapability)
          .speakRealtimeChunk(text);
    }
    return gateway.speak(text);
  }

  Future<void> stopImmediately() {
    final gateway = this;
    if (gateway is RealtimeTextToSpeechCapability) {
      return (gateway as RealtimeTextToSpeechCapability)
          .stopRealtimeImmediately();
    }
    return gateway.stop();
  }
}
