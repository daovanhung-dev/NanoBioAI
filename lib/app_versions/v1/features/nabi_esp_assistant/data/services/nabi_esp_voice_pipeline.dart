import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_whisper_ggml/flutter_whisper.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/data/datasources/voice_chat_turn_datasource.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/entities/voice_chat_message.dart';
import 'package:nano_app/core/ai_local/local_ai_runtime_service.dart';
import 'package:opus_codec_dart/opus_codec_dart.dart';
import 'package:path_provider/path_provider.dart';

import 'nabi_esp_audio_frames.dart';

typedef NabiEspProgressCallback = void Function(double progress);

class NabiEspAssistantReply {
  const NabiEspAssistantReply({
    required this.transcript,
    required this.text,
    required this.opusPackets,
  });

  final String transcript;
  final String text;
  final List<Uint8List> opusPackets;
}

/// Local STT → the app's existing safe local LLM turn path → offline TTS.
/// Audio and transcript are held only in memory except for a temporary WAV
/// created by Android TTS and deleted immediately after it is read.
class NabiEspVoicePipeline {
  NabiEspVoicePipeline({
    VoiceChatTurnDatasource? turnDatasource,
    FlutterTts? tts,
  }) : _turnDatasource = turnDatasource ?? LocalVoiceChatTurnDatasource(),
       _tts = tts ?? FlutterTts();

  static const _maxHistoryMessages = 12;
  static const _maxTranscriptSamples = 16000 * 60;
  static const _maxTtsFileBytes = 10 * 1024 * 1024;
  static const _maxTtsSamples = 24000 * 60;
  static const _whisperModelDirectoryName = 'nabi_esp_whisper';

  final VoiceChatTurnDatasource _turnDatasource;
  final FlutterTts _tts;
  final List<VoiceChatMessage> _history = [];
  FlutterWhisper? _whisper;
  String? _voiceName;
  String? _voiceLocale;
  bool _disposed = false;

  bool get isReady => _whisper != null && _voiceName != null;

  Future<void> prepare({NabiEspProgressCallback? onWhisperProgress}) async {
    final runtime = LocalAiRuntimeService.instance;
    if (!await runtime.hasInstalledSelectedTextModel()) {
      throw StateError('Chưa cài model AI local trong Nabi.');
    }
    if (!await runtime.loadSelectedTextModel()) {
      throw StateError('Không nạp được model AI local đã chọn.');
    }

    if (_whisper == null) {
      final support = await getApplicationSupportDirectory();
      final modelDirectory = Directory(
        '${support.path}/models/$_whisperModelDirectoryName',
      );
      await modelDirectory.create(recursive: true);
      _whisper = await FlutterWhisper.loadModel(
        model: WhisperModels.tinyQ5_1,
        modelDirectory: modelDirectory.path,
        config: const WhisperModelConfig(useGpu: false),
        onDownloadProgress: (progress) =>
            onWhisperProgress?.call(progress.fraction),
      );
    }

    await _prepareOfflineVietnameseTts();
  }

  Future<void> _prepareOfflineVietnameseTts() async {
    await _tts.awaitSynthCompletion(true);
    final rawVoices = await _tts.getVoices;
    if (rawVoices is! List) {
      throw StateError('Không lấy được danh sách giọng đọc trên điện thoại.');
    }
    final voices = rawVoices
        .whereType<Map>()
        .map((voice) => voice.map((key, value) => MapEntry('$key', '$value')))
        .where(
          (voice) =>
              voice['network_required'] == '0' &&
              (voice['locale'] ?? '').toLowerCase().startsWith('vi'),
        )
        .toList();
    if (voices.isEmpty) {
      throw StateError(
        'Điện thoại chưa cài giọng TTS tiếng Việt hoạt động ngoại tuyến.',
      );
    }
    final selected = voices.first;
    _voiceName = selected['name'];
    _voiceLocale = selected['locale'] ?? 'vi-VN';
    final name = _voiceName;
    if (name == null || name.isEmpty) {
      throw StateError('Giọng TTS ngoại tuyến không có tên hợp lệ.');
    }
    await _tts.setVoice({'name': name, 'locale': _voiceLocale!});
    await _tts.setLanguage(_voiceLocale!);
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
  }

  Future<NabiEspAssistantReply?> process(Int16List pcm16) async {
    if (!isReady || _disposed) {
      throw StateError('AI local chưa sẵn sàng.');
    }
    if (pcm16.isEmpty || pcm16.length > _maxTranscriptSamples) {
      throw const FormatException('Audio đầu vào vượt giới hạn phiên.');
    }
    final samples = Float32List(pcm16.length);
    for (var index = 0; index < pcm16.length; index++) {
      samples[index] = pcm16[index] / 32768.0;
    }
    final transcript = (await _whisper!.transcribe(
      samples,
      config: const WhisperTranscribeConfig(
        language: 'vi',
        threads: 2,
        noContext: true,
      ),
    )).text.trim();
    if (transcript.isEmpty) return null;

    final historySnapshot = List<VoiceChatMessage>.unmodifiable(_history);
    final answer = await _turnDatasource.sendTurn(
      message: transcript,
      history: historySnapshot,
    );
    final packets = await _synthesizeOpus(answer);
    _history
      ..add(VoiceChatMessage(role: VoiceChatRole.user, text: transcript))
      ..add(VoiceChatMessage(role: VoiceChatRole.model, text: answer));
    if (_history.length > _maxHistoryMessages) {
      _history.removeRange(0, _history.length - _maxHistoryMessages);
    }
    return NabiEspAssistantReply(
      transcript: transcript,
      text: answer,
      opusPackets: packets,
    );
  }

  Future<List<Uint8List>> _synthesizeOpus(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return const [];
    await _tts.setVoice({'name': _voiceName!, 'locale': _voiceLocale!});
    await _tts.setLanguage(_voiceLocale!);
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/nabi_esp_tts_${DateTime.now().microsecondsSinceEpoch}.wav',
    );
    try {
      await _tts.synthesizeToFile(cleanText, file.path, true);
      await _tts.awaitSynthCompletion(true);
      for (var attempt = 0; attempt < 50; attempt++) {
        if (await file.exists() && await file.length() > 44) break;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (!await file.exists() || await file.length() <= 44) {
        throw StateError('Android TTS không tạo được audio.');
      }
      if (await file.length() > _maxTtsFileBytes) {
        throw StateError('Audio TTS vượt giới hạn phiên.');
      }
      final wav = await _readWavAsMonoPcm16(file);
      if (wav.samples.length > _maxTtsSamples * 2) {
        throw StateError('Audio TTS dài hơn giới hạn phiên.');
      }
      final pcm = nabiEspResample(wav.samples, wav.sampleRate, 24000);
      if (pcm.isEmpty || pcm.length > _maxTtsSamples) {
        throw StateError('Audio TTS dài hơn giới hạn phiên.');
      }
      final encoder = SimpleOpusEncoder(
        sampleRate: 24000,
        channels: 1,
        application: Application.audio,
      );
      try {
        const samplesPerFrame = 1440; // 24 kHz mono, 60 ms.
        final packets = <Uint8List>[];
        for (var offset = 0; offset < pcm.length; offset += samplesPerFrame) {
          final frame = Int16List(samplesPerFrame);
          final available = math.min(samplesPerFrame, pcm.length - offset);
          frame.setRange(0, available, pcm, offset);
          packets.add(encoder.encode(input: frame));
        }
        return packets;
      } finally {
        encoder.destroy();
      }
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> clearConversation() async {
    _history.clear();
  }

  Future<void> dispose() async {
    _disposed = true;
    await _whisper?.dispose();
    _whisper = null;
    try {
      await _tts.stop();
    } catch (_) {
      // Runtime cleanup must not surface TTS engine errors.
    }
  }
}

class _WavPcm {
  const _WavPcm(this.samples, this.sampleRate);

  final Int16List samples;
  final int sampleRate;
}

Future<_WavPcm> _readWavAsMonoPcm16(File file) async {
  final bytes = await file.readAsBytes();
  final data = ByteData.sublistView(bytes);
  if (bytes.length < 44 ||
      String.fromCharCodes(bytes.sublist(0, 4)) != 'RIFF') {
    throw const FormatException('TTS audio không phải WAV PCM.');
  }
  var offset = 12;
  var channels = 0;
  var sampleRate = 0;
  var bitsPerSample = 0;
  var format = 0;
  var audioOffset = -1;
  var audioLength = 0;
  while (offset + 8 <= bytes.length) {
    final name = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final length = data.getUint32(offset + 4, Endian.little);
    final start = offset + 8;
    if (length > bytes.length - start) break;
    if (name == 'fmt ' && length >= 16) {
      format = data.getUint16(start, Endian.little);
      channels = data.getUint16(start + 2, Endian.little);
      sampleRate = data.getUint32(start + 4, Endian.little);
      bitsPerSample = data.getUint16(start + 14, Endian.little);
    } else if (name == 'data') {
      audioOffset = start;
      audioLength = length;
      break;
    }
    offset = start + length + (length.isOdd ? 1 : 0);
  }
  if (audioOffset < 0 ||
      channels < 1 ||
      sampleRate < 1 ||
      format != 1 ||
      bitsPerSample != 16 ||
      audioLength.isOdd) {
    throw const FormatException('Android TTS WAV không phải PCM16.');
  }
  final sampleCount = audioLength ~/ 2 ~/ channels;
  final mono = Int16List(sampleCount);
  for (var index = 0; index < sampleCount; index++) {
    var sum = 0;
    for (var channel = 0; channel < channels; channel++) {
      sum += data.getInt16(
        audioOffset + (index * channels + channel) * 2,
        Endian.little,
      );
    }
    mono[index] = sum ~/ channels;
  }
  return _WavPcm(mono, sampleRate);
}
