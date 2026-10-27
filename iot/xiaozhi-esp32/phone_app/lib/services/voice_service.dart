import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:opus_codec_dart/opus_codec_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoiceService {
  final FlutterTts _tts = FlutterTts();
  List<Map<String, String>> voices = const [];
  String? selectedVoiceName;
  String? selectedVoiceLocale;
  double speechRate = 0.48;
  double pitch = 1.0;

  bool get isReady =>
      selectedVoiceName != null &&
      voices.any((voice) => voice['name'] == selectedVoiceName);

  bool get selectedVoiceIsOffline => voices.any(
    (voice) =>
        voice['name'] == selectedVoiceName && voice['network_required'] == '0',
  );

  Future<void> initialize() async {
    await _tts.awaitSynthCompletion(true);
    final prefs = await SharedPreferences.getInstance();
    selectedVoiceName = prefs.getString('tts_voice_name');
    selectedVoiceLocale = prefs.getString('tts_voice_locale');
    speechRate = prefs.getDouble('tts_rate') ?? speechRate;
    pitch = prefs.getDouble('tts_pitch') ?? pitch;
    final values = await _tts.getVoices;
    if (values is List) {
      voices = values
          .whereType<Map>()
          .map((voice) => voice.map((key, value) => MapEntry('$key', '$value')))
          .toList();
    }
    if (!isReady && voices.isNotEmpty) {
      final offlineVoices = voices
          .where((voice) => voice['network_required'] == '0')
          .toList();
      final candidates = offlineVoices.isNotEmpty ? offlineVoices : voices;
      final vietnamese = candidates
          .where(
            (voice) => (voice['locale'] ?? '').toLowerCase().startsWith('vi'),
          )
          .firstOrNull;
      final selected = vietnamese ?? candidates.first;
      selectedVoiceName = selected['name'];
      selectedVoiceLocale = selected['locale'];
    }
  }

  Future<void> selectVoice(Map<String, String> voice) async {
    selectedVoiceName = voice['name'];
    selectedVoiceLocale = voice['locale'];
    await _saveSettings();
  }

  Future<void> setRate(double value) async {
    speechRate = value;
    await _saveSettings();
  }

  Future<void> setPitch(double value) async {
    pitch = value;
    await _saveSettings();
  }

  Future<List<Uint8List>> synthesizeOpus(String text) async {
    if (text.trim().isEmpty) return const [];
    if (voices.isEmpty) await initialize();
    if (selectedVoiceName != null) {
      await _tts.setVoice({
        'name': selectedVoiceName!,
        'locale': selectedVoiceLocale ?? 'vi-VN',
      });
    }
    await _tts.setLanguage(selectedVoiceLocale ?? 'vi-VN');
    await _tts.setSpeechRate(speechRate);
    await _tts.setPitch(pitch);

    final directory = await getTemporaryDirectory();
    final output = File('${directory.path}/xiaozhi_reply.wav');
    if (await output.exists()) await output.delete();
    await _tts.synthesizeToFile(text, output.path, true);
    await _tts.awaitSynthCompletion(true);

    for (var attempt = 0; attempt < 50 && !await output.exists(); attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (!await output.exists()) {
      throw StateError('Android TTS không tạo được file âm thanh.');
    }
    final pcm = await _readWavAsMonoPcm16(output);
    final resampled = _resample(pcm.samples, pcm.sampleRate, 24000);
    final encoder = SimpleOpusEncoder(
      sampleRate: 24000,
      channels: 1,
      application: Application.audio,
    );
    try {
      const samplesPerFrame = 1440; // 24 kHz, 60 ms, mono.
      final packets = <Uint8List>[];
      for (
        var offset = 0;
        offset < resampled.length;
        offset += samplesPerFrame
      ) {
        final frame = Int16List(samplesPerFrame);
        final available = math.min(samplesPerFrame, resampled.length - offset);
        frame.setRange(0, available, resampled, offset);
        packets.add(encoder.encode(input: frame));
      }
      return packets;
    } finally {
      encoder.destroy();
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_voice_name', selectedVoiceName ?? '');
    await prefs.setString('tts_voice_locale', selectedVoiceLocale ?? 'vi-VN');
    await prefs.setDouble('tts_rate', speechRate);
    await prefs.setDouble('tts_pitch', pitch);
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
    throw const FormatException('Android TTS không tạo WAV PCM hợp lệ.');
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
    if (name == 'fmt ' && length >= 16 && start + length <= bytes.length) {
      format = data.getUint16(start, Endian.little);
      channels = data.getUint16(start + 2, Endian.little);
      sampleRate = data.getUint32(start + 4, Endian.little);
      bitsPerSample = data.getUint16(start + 14, Endian.little);
    } else if (name == 'data' && start + length <= bytes.length) {
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
      bitsPerSample != 16) {
    throw const FormatException('Chỉ hỗ trợ TTS WAV PCM 16-bit.');
  }
  final sampleCount = audioLength ~/ 2 ~/ channels;
  final mono = Int16List(sampleCount);
  for (var i = 0; i < sampleCount; i++) {
    var sum = 0;
    for (var channel = 0; channel < channels; channel++) {
      sum += data.getInt16(
        audioOffset + (i * channels + channel) * 2,
        Endian.little,
      );
    }
    mono[i] = sum ~/ channels;
  }
  return _WavPcm(mono, sampleRate);
}

Int16List _resample(Int16List input, int inputRate, int outputRate) {
  if (inputRate == outputRate) return input;
  final outputLength = (input.length * outputRate / inputRate).floor();
  final output = Int16List(outputLength);
  for (var index = 0; index < outputLength; index++) {
    final position = index * inputRate / outputRate;
    final first = position.floor();
    final second = math.min(first + 1, input.length - 1);
    final fraction = position - first;
    output[index] = (input[first] * (1 - fraction) + input[second] * fraction)
        .round()
        .clamp(-32768, 32767);
  }
  return output;
}
