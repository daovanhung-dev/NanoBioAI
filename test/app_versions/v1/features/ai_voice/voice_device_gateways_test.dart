import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/data/gateways/flutter_tts_gateway.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/data/gateways/speech_to_text_gateway.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/gateways/voice_gateways.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceSpeechRecognitionGateway', () {
    late _SpeechMethodChannelHarness channel;

    setUp(() {
      channel = _SpeechMethodChannelHarness();
      channel.install();
    });

    tearDown(() => channel.uninstall());

    test(
      'passes a three-minute listen window and accepts the null listen result',
      () async {
        final gateway = DeviceSpeechRecognitionGateway(
          speech: SpeechToText.withMethodChannel(),
        );

        final transcriptFuture = gateway.listenOnce();
        await channel.nextListen;

        expect(channel.initializeArguments?['noBluetooth'], isTrue);
        expect(channel.listenArguments?['localeId'], 'vi_VN');
        expect(
          channel.listenArguments?['listenMode'],
          ListenMode.dictation.index,
        );
        expect(channel.listenArguments?['listenFor'], 180000);
        // The selected cutoff is armed only after speech is detected, so a
        // fast setting cannot stop the recognizer before the user speaks.
        expect(channel.listenArguments?['pauseFor'], isNull);
        expect(channel.listenArguments?['autoPunctuation'], isTrue);

        await channel.sendStatus(SpeechToText.listeningStatus);
        await channel.sendResult('xin chào', finalResult: false);
        await channel.sendResult('xin chào Nabi', finalResult: true);
        await channel.nextStop;

        var completed = false;
        unawaited(transcriptFuture.then((_) => completed = true));
        await Future<void>.delayed(Duration.zero);
        expect(completed, isFalse);

        await channel.sendStatus(SpeechToText.doneStatus);

        expect(await transcriptFuture, 'xin chào Nabi');
        expect(channel.listenCount, 1);
        expect(channel.stopCount, 1);
        expect(channel.cancelCount, 0);
      },
    );

    test(
      'does not apply the 200 ms cutoff before speech is detected',
      () async {
        final gateway = DeviceSpeechRecognitionGateway(
          speech: SpeechToText.withMethodChannel(),
        );

        final transcriptFuture = gateway.listenOnce(
          pauseFor: const Duration(milliseconds: 200),
        );
        await channel.nextListen;
        await channel.sendStatus(SpeechToText.listeningStatus);

        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(channel.stopCount, 0);

        await channel.sendResult('xin chào', finalResult: false);
        await channel.nextStop.timeout(const Duration(seconds: 1));
        await channel.sendStatus(SpeechToText.doneStatus);
        await channel.sendResult('xin chào', finalResult: true);

        expect(await transcriptFuture, 'xin chào');
      },
    );

    for (final silenceTimeout in <Duration>[
      Duration(milliseconds: 200),
      Duration(milliseconds: 500),
      Duration(seconds: 1),
      Duration(seconds: 2),
    ]) {
      test(
        'stops after ${silenceTimeout.inMilliseconds} ms without a new result',
        () async {
          final gateway = DeviceSpeechRecognitionGateway(
            speech: SpeechToText.withMethodChannel(),
          );

          final transcriptFuture = gateway.listenOnce(pauseFor: silenceTimeout);
          await channel.nextListen;
          expect(channel.listenArguments?['pauseFor'], isNull);
          await channel.sendStatus(SpeechToText.listeningStatus);

          final stopwatch = Stopwatch()..start();
          await channel.sendResult('Nabi ơi', finalResult: false);
          await channel.nextStop.timeout(
            silenceTimeout + const Duration(seconds: 1),
          );
          stopwatch.stop();

          expect(
            stopwatch.elapsed,
            greaterThanOrEqualTo(
              silenceTimeout - const Duration(milliseconds: 40),
            ),
          );

          await channel.sendStatus(SpeechToText.doneStatus);
          await channel.sendResult('Nabi ơi', finalResult: true);
          expect(await transcriptFuture, 'Nabi ơi');
          expect(channel.stopCount, 1);
          expect(channel.cancelCount, 0);
        },
      );
    }

    test(
      'measures silence from the latest changed recognition result',
      () async {
        final gateway = DeviceSpeechRecognitionGateway(
          speech: SpeechToText.withMethodChannel(),
        );

        final transcriptFuture = gateway.listenOnce(
          pauseFor: const Duration(milliseconds: 200),
        );
        await channel.nextListen;
        await channel.sendStatus(SpeechToText.listeningStatus);
        await channel.sendResult('tôi muốn', finalResult: false);

        await Future<void>.delayed(const Duration(milliseconds: 150));
        await channel.sendResult('tôi muốn hỏi', finalResult: false);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(channel.stopCount, 0);

        await channel.nextStop.timeout(const Duration(milliseconds: 250));
        await channel.sendStatus(SpeechToText.doneStatus);
        await channel.sendResult('tôi muốn hỏi', finalResult: true);

        expect(await transcriptFuture, 'tôi muốn hỏi');
      },
    );

    test(
      'does not start another listen before silence stop settles natively',
      () async {
        final gateway = DeviceSpeechRecognitionGateway(
          speech: SpeechToText.withMethodChannel(),
        );

        final firstListen = gateway.listenOnce(
          pauseFor: const Duration(milliseconds: 200),
        );
        await channel.nextListen;
        await channel.sendStatus(SpeechToText.listeningStatus);
        await channel.sendResult('lượt một', finalResult: false);
        await channel.nextStop.timeout(const Duration(seconds: 1));

        await expectLater(
          gateway.listenOnce(),
          throwsA(isA<SpeechRecognitionUnavailableException>()),
        );
        expect(channel.listenCount, 1);

        await channel.sendStatus(SpeechToText.doneStatus);
        await channel.sendResult('lượt một', finalResult: true);
        expect(await firstListen, 'lượt một');

        channel.prepareNextListen();
        final secondListen = gateway.listenOnce();
        await channel.nextListen;
        await channel.sendStatus(SpeechToText.listeningStatus);
        await channel.sendStatus('doneNoResult');

        expect(await secondListen, isEmpty);
        expect(channel.listenCount, 2);
      },
    );

    test(
      'does not start another listen before native cancellation settles',
      () async {
        final gateway = DeviceSpeechRecognitionGateway(
          speech: SpeechToText.withMethodChannel(),
        );

        final firstListen = gateway.listenOnce();
        await channel.nextListen;
        await channel.sendStatus(SpeechToText.listeningStatus);
        await channel.sendResult('không giữ câu này', finalResult: false);

        final cancelFuture = gateway.cancel();
        await channel.nextCancel;

        await expectLater(
          gateway.listenOnce(),
          throwsA(isA<SpeechRecognitionUnavailableException>()),
        );
        expect(channel.listenCount, 1);

        await channel.sendStatus(SpeechToText.notListeningStatus);
        await cancelFuture;
        expect(await firstListen, isEmpty);

        channel.prepareNextListen();
        final secondListen = gateway.listenOnce();
        await channel.nextListen;
        await channel.sendStatus(SpeechToText.listeningStatus);
        await channel.sendStatus('doneNoResult');

        expect(await secondListen, isEmpty);
        expect(channel.listenCount, 2);
      },
    );

    test(
      'stop waits for native terminal status and preserves partial words',
      () async {
        final gateway = DeviceSpeechRecognitionGateway(
          speech: SpeechToText.withMethodChannel(),
        );

        final transcriptFuture = gateway.listenOnce();
        await channel.nextListen;
        await channel.sendStatus(SpeechToText.listeningStatus);
        await channel.sendResult('câu đang nói', finalResult: false);

        final stopFuture = gateway.stop();
        await channel.nextStop;

        var stopCompleted = false;
        unawaited(stopFuture.then((_) => stopCompleted = true));
        await Future<void>.delayed(Duration.zero);
        expect(stopCompleted, isFalse);

        await channel.sendStatus(SpeechToText.notListeningStatus);

        await stopFuture;
        expect(await transcriptFuture, 'câu đang nói');
        expect(channel.stopCount, 1);
      },
    );

    test('fails safely when native listening never starts', () async {
      final gateway = DeviceSpeechRecognitionGateway(
        speech: SpeechToText.withMethodChannel(),
        startTimeout: const Duration(milliseconds: 10),
        terminalTimeout: const Duration(milliseconds: 10),
      );

      await expectLater(
        gateway.listenOnce(),
        throwsA(isA<SpeechRecognitionUnavailableException>()),
      );

      expect(channel.listenCount, 1);
      expect(channel.cancelCount, 1);
    });

    test(
      'maps recognizer permission errors and cancels the active session',
      () async {
        final gateway = DeviceSpeechRecognitionGateway(
          speech: SpeechToText.withMethodChannel(),
          terminalTimeout: const Duration(milliseconds: 20),
        );

        final transcriptExpectation = expectLater(
          gateway.listenOnce(),
          throwsA(isA<SpeechRecognitionPermissionDeniedException>()),
        );
        await channel.nextListen;
        await channel.sendStatus(SpeechToText.listeningStatus);
        await channel.sendError('error_permission', permanent: true);
        await channel.nextCancel;
        await channel.sendStatus(SpeechToText.notListeningStatus);

        await transcriptExpectation;
        expect(channel.cancelCount, 1);
      },
    );

    test(
      'maps transient recognizer errors and cancels the active session',
      () async {
        final gateway = DeviceSpeechRecognitionGateway(
          speech: SpeechToText.withMethodChannel(),
          terminalTimeout: const Duration(milliseconds: 20),
        );

        final transcriptExpectation = expectLater(
          gateway.listenOnce(),
          throwsA(isA<SpeechRecognitionUnavailableException>()),
        );
        await channel.nextListen;
        await channel.sendStatus(SpeechToText.listeningStatus);
        await channel.sendError('error_network', permanent: false);
        await channel.nextCancel;
        await channel.sendStatus(SpeechToText.notListeningStatus);

        await transcriptExpectation;
        expect(channel.cancelCount, 1);
      },
    );
  });

  group('DeviceTextToSpeechGateway', () {
    late _TtsMethodChannelHarness channel;

    setUp(() {
      channel = _TtsMethodChannelHarness();
      channel.install();
    });

    tearDown(() => channel.uninstall());

    test('requires vi-VN and waits for successful speech completion', () async {
      final gateway = DeviceTextToSpeechGateway(tts: FlutterTts());

      await gateway.speak('  Xin chào bạn  ');

      expect(channel.methods, [
        'isLanguageAvailable',
        'awaitSpeakCompletion',
        'setLanguage',
        'setSpeechRate',
        'setVolume',
        'setPitch',
        'stop',
        'speak',
      ]);
      expect(channel.arguments['isLanguageAvailable'], 'vi-VN');
      expect(channel.arguments['awaitSpeakCompletion'], isTrue);
      expect(channel.arguments['setLanguage'], 'vi-VN');
      expect(channel.arguments['speak'], 'Xin chào bạn');
    });

    test('fails initialization when vi-VN is unavailable', () async {
      channel.languageAvailable = false;
      final gateway = DeviceTextToSpeechGateway(tts: FlutterTts());

      await expectLater(
        gateway.initialize(),
        throwsA(isA<TextToSpeechUnavailableException>()),
      );

      expect(channel.methods, ['isLanguageAvailable']);
    });

    test('stops TTS and fails safely when completion times out', () async {
      channel.speakResult = Completer<Object?>().future;
      final gateway = DeviceTextToSpeechGateway(
        tts: FlutterTts(),
        speakTimeout: const Duration(milliseconds: 10),
      );

      await expectLater(
        gateway.speak('Nabi đang trả lời'),
        throwsA(isA<TextToSpeechUnavailableException>()),
      );

      expect(channel.stopCount, 2);
    });

    test('does not initialize or invoke native TTS for blank text', () async {
      final gateway = DeviceTextToSpeechGateway(tts: FlutterTts());

      await gateway.speak('   ');

      expect(channel.methods, isEmpty);
    });
  });
}

class _SpeechMethodChannelHarness {
  static const MethodChannel _channel = MethodChannel(
    'plugin.csdcorp.com/speech_to_text',
  );
  static const StandardMethodCodec _codec = StandardMethodCodec();

  Map<dynamic, dynamic>? initializeArguments;
  Map<dynamic, dynamic>? listenArguments;
  int listenCount = 0;
  int stopCount = 0;
  int cancelCount = 0;

  Completer<void> _listen = Completer<void>();
  Completer<void> _stop = Completer<void>();
  Completer<void> _cancel = Completer<void>();

  Future<void> get nextListen => _listen.future;
  Future<void> get nextStop => _stop.future;
  Future<void> get nextCancel => _cancel.future;

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, _handleMethodCall);
  }

  void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  }

  void prepareNextListen() {
    _listen = Completer<void>();
    _stop = Completer<void>();
    _cancel = Completer<void>();
  }

  Future<Object?> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'initialize':
        initializeArguments = call.arguments as Map<dynamic, dynamic>?;
        return true;
      case 'has_permission':
        return true;
      case 'listen':
        listenArguments = call.arguments as Map<dynamic, dynamic>?;
        listenCount++;
        if (!_listen.isCompleted) _listen.complete();
        return true;
      case 'stop':
        stopCount++;
        if (!_stop.isCompleted) _stop.complete();
        return true;
      case 'cancel':
        cancelCount++;
        if (!_cancel.isCompleted) _cancel.complete();
        return true;
    }
    return null;
  }

  Future<void> sendStatus(String status) =>
      _sendCallback(SpeechToText.notifyStatusMethod, status);

  Future<void> sendResult(String words, {required bool finalResult}) {
    return _sendCallback(
      SpeechToText.textRecognitionMethod,
      jsonEncode(<String, Object>{
        'alternates': <Map<String, Object?>>[
          <String, Object?>{
            'recognizedWords': words,
            'recognizedPhrases': null,
            'confidence': 0.9,
          },
        ],
        'resultType': finalResult ? 2 : 0,
      }),
    );
  }

  Future<void> sendError(String message, {required bool permanent}) {
    return _sendCallback(
      SpeechToText.notifyErrorMethod,
      jsonEncode(<String, Object>{'errorMsg': message, 'permanent': permanent}),
    );
  }

  Future<void> _sendCallback(String method, Object? arguments) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          _channel.name,
          _codec.encodeMethodCall(MethodCall(method, arguments)),
          (_) {},
        );
  }
}

class _TtsMethodChannelHarness {
  static const MethodChannel _channel = MethodChannel('flutter_tts');

  final List<String> methods = <String>[];
  final Map<String, Object?> arguments = <String, Object?>{};
  bool languageAvailable = true;
  Future<Object?>? speakResult;
  int stopCount = 0;

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, _handleMethodCall);
  }

  void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  }

  Future<Object?> _handleMethodCall(MethodCall call) async {
    methods.add(call.method);
    arguments[call.method] = call.arguments;
    switch (call.method) {
      case 'isLanguageAvailable':
        return languageAvailable;
      case 'speak':
        return speakResult == null ? 1 : await speakResult;
      case 'stop':
        stopCount++;
        return 1;
      default:
        return 1;
    }
  }
}
