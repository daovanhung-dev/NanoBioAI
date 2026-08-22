import 'dart:convert';
import 'dart:typed_data';

import '../../domain/entities/voice_live_event.dart';

class GeminiLiveServerMessage {
  final List<VoiceLiveEvent> events;
  final String? resumptionHandle;
  final bool? resumptionAvailable;
  final bool setupComplete;
  final bool goAway;

  const GeminiLiveServerMessage({
    required this.events,
    this.resumptionHandle,
    this.resumptionAvailable,
    this.setupComplete = false,
    this.goAway = false,
  });
}

/// Deliberately contains no provider response details. The gateway reports a
/// user-safe failure while keeping diagnostics free of credentials and audio.
class GeminiLiveProtocolException implements Exception {
  const GeminiLiveProtocolException();
}

abstract final class GeminiLiveProtocol {
  const GeminiLiveProtocol._();

  static Map<String, Object?> setup({
    required String model,
    required String systemInstruction,
    String? resumptionHandle,
  }) {
    final normalizedModel = model.replaceFirst(RegExp(r'^models/'), '');
    return {
      'setup': {
        'model': 'models/$normalizedModel',
        'generationConfig': {
          'responseModalities': const ['AUDIO'],
        },
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction},
          ],
        },
        'inputAudioTranscription': const {},
        'outputAudioTranscription': const {},
        'realtimeInputConfig': {
          'automaticActivityDetection': {
            'prefixPaddingMs': 300,
            'silenceDurationMs': 700,
          },
        },
        // Preserve the live conversation beyond a provider context-window
        // rollover instead of terminating it locally after a fixed duration.
        'contextWindowCompression': {'slidingWindow': const {}},
        'sessionResumption': {
          if (resumptionHandle != null) 'handle': resumptionHandle,
        },
      },
    };
  }

  static Map<String, Object?> audio(Uint8List pcm) {
    return {
      'realtimeInput': {
        'audio': {
          'data': base64Encode(pcm),
          'mimeType': 'audio/pcm;rate=16000',
        },
      },
    };
  }

  static const Map<String, Object?> audioStreamEnd = {
    'realtimeInput': {'audioStreamEnd': true},
  };

  static GeminiLiveServerMessage parse(Object? raw) {
    final root = _map(raw is String ? jsonDecode(raw) : raw);
    if (root == null) {
      throw const FormatException('Gemini Live returned an invalid message.');
    }
    if (root.containsKey('error')) {
      throw const GeminiLiveProtocolException();
    }

    final events = <VoiceLiveEvent>[];
    final serverContent = _map(root['serverContent']);
    if (serverContent != null) {
      final inputText = _text(
        _map(serverContent['inputTranscription'])?['text'],
      );
      if (inputText != null) {
        events.add(VoiceLiveEvent.inputTranscript(inputText));
      }

      final outputText = _text(
        _map(serverContent['outputTranscription'])?['text'],
      );
      if (outputText != null) {
        events.add(VoiceLiveEvent.outputTranscript(outputText));
      }

      final modelTurn = _map(serverContent['modelTurn']);
      final parts = modelTurn?['parts'];
      if (parts is List) {
        for (final part in parts) {
          final inlineData = _map(_map(part)?['inlineData']);
          final encoded = _text(inlineData?['data']);
          if (encoded == null) continue;
          events.add(
            VoiceLiveEvent.outputAudio(
              Uint8List.fromList(base64Decode(encoded)),
            ),
          );
        }
      }

      if (serverContent['interrupted'] == true) {
        events.add(const VoiceLiveEvent.interrupted());
      }
      if (serverContent['turnComplete'] == true) {
        events.add(const VoiceLiveEvent.turnCompleted());
      }
    }

    final update = _map(root['sessionResumptionUpdate']);
    final resumptionAvailable = update == null
        ? null
        : update['resumable'] == true;
    final handle = resumptionAvailable == true
        ? _text(update?['newHandle'])
        : null;
    return GeminiLiveServerMessage(
      events: events,
      resumptionHandle: handle,
      resumptionAvailable: resumptionAvailable,
      setupComplete: root.containsKey('setupComplete'),
      goAway: root['goAway'] is Map,
    );
  }

  static Map<String, Object?>? _map(Object? value) {
    if (value is! Map) return null;
    return Map<String, Object?>.fromEntries(
      value.entries.map((entry) => MapEntry(entry.key.toString(), entry.value)),
    );
  }

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
