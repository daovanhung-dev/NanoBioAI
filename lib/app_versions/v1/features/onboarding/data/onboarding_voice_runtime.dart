import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_whisper_ggml/flutter_whisper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:nano_app/core/platform/web_runtime_support.dart' as web_support;

/// On-device Vietnamese speech input for onboarding. PCM is streamed directly
/// from the microphone to Whisper and is never written to a file.
class OnboardingVoiceRuntime {
  OnboardingVoiceRuntime({AudioRecorder? recorder, FlutterTts? tts})
    : _recorder = recorder ?? AudioRecorder(),
      _tts = tts ?? FlutterTts();

  static const modelDirectoryName = 'nabi_esp_whisper';
  static const maxRecording = Duration(seconds: 12);
  static const _minimumSpeech = Duration(milliseconds: 350);
  static const _trailingSilence = Duration(milliseconds: 1100);
  static const _silenceThreshold = 420.0;

  final AudioRecorder _recorder;
  final FlutterTts _tts;
  FlutterWhisper? _whisper;
  bool _ttsReady = false;
  bool _disposed = false;
  Completer<void>? _captureCancelled;

  bool get isSupported => platformIsSupported;

  static bool get platformIsSupported => kIsWeb
      ? web_support.isSecureCrossOriginIsolated
      : (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> prepare({
    void Function(double progress)? onDownloadProgress,
  }) async {
    if (!isSupported) throw const OnboardingVoiceUnavailableException();
    if (_disposed) throw StateError('Onboarding voice session was disposed.');

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) throw const OnboardingVoicePermissionException();

    if (_whisper == null && kIsWeb) {
      _whisper = await FlutterWhisper.loadModel(
        model: WhisperModels.tinyQ5_1,
        config: const WhisperModelConfig(useGpu: false),
        onModelProgress: (progress) => onDownloadProgress?.call(progress / 100),
      );
    } else if (_whisper == null) {
      final supportDirectory = await getApplicationSupportDirectory();
      final modelDirectory =
          '${supportDirectory.path}/models/$modelDirectoryName';
      _whisper = await FlutterWhisper.loadModel(
        model: WhisperModels.tinyQ5_1,
        modelDirectory: modelDirectory,
        config: const WhisperModelConfig(useGpu: false),
        onDownloadProgress: (progress) =>
            onDownloadProgress?.call(progress.fraction),
      );
    }
    if (!kIsWeb) await prepareSpeech();
  }

  Future<void> prepareSpeech() async {
    if (_disposed) throw StateError('Onboarding voice session was disposed.');
    if (_ttsReady) return;
    if (kIsWeb) {
      // Browser speech synthesis can use a remote voice. Keep web onboarding
      // voice input on-device and let the visible question remain the prompt.
      _ttsReady = true;
      return;
    }
    try {
      await _tts.awaitSpeakCompletion(true);
      final available = await _tts.isLanguageAvailable('vi-VN');
      if (available != true) throw const OnboardingVoiceUnavailableException();
      final voicesRaw = await _tts.getVoices;
      if (voicesRaw is List) {
        final vietnameseVoices = voicesRaw
            .whereType<Map>()
            .map(
              (voice) => voice.map((key, value) => MapEntry('$key', '$value')),
            )
            .where(
              (voice) => (voice['locale'] ?? '').toLowerCase().startsWith('vi'),
            )
            .toList(growable: false);
        if (vietnameseVoices.isEmpty) {
          throw const OnboardingVoiceUnavailableException();
        }
        final offlineVoice = vietnameseVoices.where((voice) {
          final required = voice['network_required']?.toLowerCase();
          return required == null || required == 'false' || required == '0';
        }).firstOrNull;
        if (vietnameseVoices.isNotEmpty && offlineVoice == null) {
          throw const OnboardingVoiceUnavailableException();
        }
        if (offlineVoice case final voice?) {
          await _tts.setVoice({
            'name': voice['name'] ?? '',
            'locale': voice['locale'] ?? 'vi-VN',
          });
          final locale = voice['locale'];
          if (locale != null && locale.isNotEmpty) {
            await _tts.setLanguage(locale);
          }
        } else {
          await _tts.setLanguage('vi-VN');
        }
      } else {
        throw const OnboardingVoiceUnavailableException();
      }
      await _tts.setSpeechRate(0.50);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _ttsReady = true;
    } on OnboardingVoiceUnavailableException {
      rethrow;
    } catch (_) {
      throw const OnboardingVoiceUnavailableException();
    }
  }

  Future<void> speak(String text) async {
    final normalized = text.trim();
    if (normalized.isEmpty || kIsWeb) return;
    await prepareSpeech();
    try {
      await _tts.stop();
      final result = await _tts
          .speak(normalized)
          .timeout(const Duration(seconds: 60));
      if (result == 0 || result == false) {
        throw const OnboardingVoiceUnavailableException();
      }
    } on TimeoutException {
      await stopSpeech();
      throw const OnboardingVoiceUnavailableException();
    }
  }

  Future<String> listenAndTranscribe() async {
    if (_whisper == null || _disposed) {
      throw StateError('Whisper has not been prepared.');
    }

    final audio = BytesBuilder(copy: false);
    final finished = Completer<void>();
    final cancelled = Completer<void>();
    _captureCancelled = cancelled;
    StreamSubscription<Uint8List>? subscription;
    Timer? timeout;
    var bytesReceived = 0;
    var speechStartedAt = 0;
    var lastVoiceAt = 0;

    try {
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
      );
      final clock = Stopwatch()..start();
      timeout = Timer(maxRecording, () {
        if (!finished.isCompleted) finished.complete();
      });
      subscription = stream.listen(
        (chunk) {
          if (chunk.isEmpty || finished.isCompleted) return;
          audio.add(chunk);
          bytesReceived += chunk.length;
          final sampleCount = chunk.length ~/ 2;
          var energy = 0.0;
          final byteData = ByteData.sublistView(chunk);
          for (var index = 0; index < sampleCount; index++) {
            final value = byteData
                .getInt16(index * 2, Endian.little)
                .toDouble();
            energy += value * value;
          }
          final rms = sampleCount == 0 ? 0.0 : math.sqrt(energy / sampleCount);
          if (rms >= _silenceThreshold) {
            speechStartedAt = clock.elapsedMilliseconds;
            lastVoiceAt = speechStartedAt;
          }
          final elapsed = clock.elapsedMilliseconds;
          final hasEnoughSpeech =
              speechStartedAt > 0 &&
              elapsed - speechStartedAt >= _minimumSpeech.inMilliseconds;
          final endedBySilence =
              hasEnoughSpeech &&
              elapsed - lastVoiceAt >= _trailingSilence.inMilliseconds;
          final tooLong = bytesReceived >= 16000 * 2 * maxRecording.inSeconds;
          if ((endedBySilence || tooLong) && !finished.isCompleted) {
            finished.complete();
          }
        },
        onError: (Object error, StackTrace stack) {
          if (!finished.isCompleted) finished.completeError(error, stack);
        },
        onDone: () {
          if (!finished.isCompleted) finished.complete();
        },
        cancelOnError: true,
      );
      await Future.any([finished.future, cancelled.future]);
      if (cancelled.isCompleted) return '';
      await _recorder.stop();
      await subscription.cancel();
      subscription = null;
      timeout.cancel();
      timeout = null;

      final bytes = audio.takeBytes();
      final sampleCount = bytes.length ~/ 2;
      if (sampleCount < 16000 * 0.35) return '';
      final samples = Float32List(sampleCount);
      final byteData = ByteData.sublistView(bytes);
      for (var index = 0; index < sampleCount; index++) {
        samples[index] = byteData.getInt16(index * 2, Endian.little) / 32768.0;
      }
      return (await _whisper!.transcribe(
        samples,
        config: const WhisperTranscribeConfig(
          language: 'vi',
          threads: 2,
          noContext: true,
        ),
      )).text.trim();
    } finally {
      if (identical(_captureCancelled, cancelled)) _captureCancelled = null;
      timeout?.cancel();
      await subscription?.cancel();
      try {
        await _recorder.stop();
      } catch (_) {
        // The recorder may already have stopped after an OS interruption.
      }
    }
  }

  Future<void> stopSpeech() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Best effort when leaving the voice flow.
    }
  }

  Future<void> stopAll() async {
    final cancelled = _captureCancelled;
    if (cancelled != null && !cancelled.isCompleted) cancelled.complete();
    try {
      await _recorder.stop();
    } catch (_) {
      // No capture may be active.
    }
    _whisper?.cancel();
    await stopSpeech();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    await stopAll();
    _disposed = true;
    try {
      await _recorder.dispose();
    } catch (_) {
      // The native recorder may already have been released by the OS.
    }
    await _whisper?.dispose();
  }
}

class OnboardingVoiceUnavailableException implements Exception {
  const OnboardingVoiceUnavailableException();
}

class OnboardingVoicePermissionException implements Exception {
  const OnboardingVoicePermissionException();
}
