import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/data/gateways/gemini_live_protocol.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/entities/voice_live_event.dart';

void main() {
  test(
    'builds a direct audio setup with Nabi instruction and automatic VAD',
    () {
      final setup = GeminiLiveProtocol.setup(
        model: 'gemini-3.1-flash-live-preview',
        systemInstruction: 'Nabi speaks Vietnamese.',
        resumptionHandle: 'resume-handle',
      );

      final content = setup['setup']! as Map<String, Object?>;
      expect(content['model'], 'models/gemini-3.1-flash-live-preview');
      expect(content.containsKey('responseModalities'), isFalse);
      expect(
        (content['generationConfig']!
            as Map<String, Object?>)['responseModalities'],
        <String>['AUDIO'],
      );
      expect(
        ((content['systemInstruction']! as Map<String, Object?>)['parts']!
                as List<Object?>)
            .single,
        <String, String>{'text': 'Nabi speaks Vietnamese.'},
      );
      final vad =
          ((content['realtimeInputConfig']!
                  as Map<String, Object?>)['automaticActivityDetection']!
              as Map<String, Object?>);
      expect(vad['silenceDurationMs'], 700);
      expect(vad['prefixPaddingMs'], 300);
      expect(
        (content['contextWindowCompression']!
            as Map<String, Object?>)['slidingWindow'],
        <String, Object?>{},
      );
      expect(
        (content['sessionResumption']! as Map<String, Object?>)['handle'],
        'resume-handle',
      );
    },
  );

  test('encodes PCM16 microphone chunks as Live realtime input', () {
    final message = GeminiLiveProtocol.audio(
      Uint8List.fromList(<int>[0, 1, 2]),
    );
    final audio =
        ((message['realtimeInput']! as Map<String, Object?>)['audio']!
            as Map<String, Object?>);

    expect(audio['mimeType'], 'audio/pcm;rate=16000');
    expect(base64Decode(audio['data']! as String), <int>[0, 1, 2]);
  });

  test(
    'parses all transcription, audio parts, interruption and completion',
    () {
      final payload = jsonEncode({
        'serverContent': {
          'inputTranscription': {'text': 'Tôi muốn hỏi'},
          'outputTranscription': {'text': 'Nabi đang trả lời'},
          'modelTurn': {
            'parts': [
              {
                'inlineData': {
                  'mimeType': 'audio/pcm;rate=24000',
                  'data': base64Encode(<int>[1, 2]),
                },
              },
              {
                'inlineData': {
                  'mimeType': 'audio/pcm;rate=24000',
                  'data': base64Encode(<int>[3, 4]),
                },
              },
            ],
          },
          'interrupted': true,
          'turnComplete': true,
        },
        'sessionResumptionUpdate': {
          'resumable': true,
          'newHandle': 'new-resume-handle',
        },
      });

      final message = GeminiLiveProtocol.parse(payload);

      expect(message.resumptionHandle, 'new-resume-handle');
      expect(message.resumptionAvailable, isTrue);
      expect(message.events.map((event) => event.type), <VoiceLiveEventType>[
        VoiceLiveEventType.inputTranscript,
        VoiceLiveEventType.outputTranscript,
        VoiceLiveEventType.outputAudio,
        VoiceLiveEventType.outputAudio,
        VoiceLiveEventType.interrupted,
        VoiceLiveEventType.turnCompleted,
      ]);
      expect(message.events[2].audio, Uint8List.fromList(<int>[1, 2]));
      expect(message.events[3].audio, Uint8List.fromList(<int>[3, 4]));
    },
  );

  test(
    'recognizes GoAway for session resumption and rejects invalid payloads',
    () {
      final goAway = GeminiLiveProtocol.parse({'goAway': {}});

      expect(goAway.goAway, isTrue);
      expect(
        GeminiLiveProtocol.parse({'setupComplete': {}}).setupComplete,
        isTrue,
      );
      expect(
        () => GeminiLiveProtocol.parse(<Object>[]),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => GeminiLiveProtocol.parse({
          'error': {'message': 'hidden'},
        }),
        throwsA(isA<GeminiLiveProtocolException>()),
      );
      final noLongerResumable = GeminiLiveProtocol.parse({
        'sessionResumptionUpdate': {'resumable': false, 'newHandle': ''},
      });
      expect(noLongerResumable.resumptionAvailable, isFalse);
      expect(noLongerResumable.resumptionHandle, isNull);
    },
  );
}
