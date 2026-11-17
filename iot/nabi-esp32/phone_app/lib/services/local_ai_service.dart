import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_whisper_ggml/flutter_whisper.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model_service.dart';

class LocalAiService extends ChangeNotifier {
  final ModelService models;
  LlamaController _llama = LlamaController();
  FlutterWhisper? _whisper;
  bool loadingLlm = false;
  bool loadingWhisper = false;
  bool get llmReady => _llmReady;
  bool get whisperReady => _whisper != null;
  bool _llmReady = false;
  String? error;
  double whisperDownloadProgress = 0;

  LocalAiService(this.models);

  Future<void> loadSelectedModel() async {
    if (!models.hasModel || loadingLlm) return;
    loadingLlm = true;
    error = null;
    notifyListeners();
    try {
      if (_llmReady) {
        await _llama.dispose();
        _llama = LlamaController();
        _llmReady = false;
      }
      await _llama.loadModel(
        modelPath: models.modelPath!,
        threads: 4,
        contextSize: 2048,
        gpuLayers: 0,
      );
      _llmReady = true;
    } catch (value) {
      error = '$value';
      _llmReady = false;
    } finally {
      loadingLlm = false;
      notifyListeners();
    }
  }

  Future<void> installSpeechModel() async {
    if (loadingWhisper || whisperReady) return;
    loadingWhisper = true;
    error = null;
    whisperDownloadProgress = 0;
    notifyListeners();
    try {
      final support = await getApplicationSupportDirectory();
      final modelDirectory = Directory('${support.path}/models/whisper');
      await modelDirectory.create(recursive: true);
      _whisper = await FlutterWhisper.loadModel(
        model: WhisperModels.tinyQ5_1,
        modelDirectory: modelDirectory.path,
        onDownloadProgress: (progress) {
          whisperDownloadProgress = progress.fraction;
          notifyListeners();
        },
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('whisper_installed', true);
    } catch (value) {
      error = '$value';
    } finally {
      loadingWhisper = false;
      notifyListeners();
    }
  }

  Future<void> unloadLanguageModel() async {
    if (!_llmReady && !await _llama.isModelLoaded()) return;
    await _llama.dispose();
    _llama = LlamaController();
    _llmReady = false;
    notifyListeners();
  }

  Future<String> transcribe(Int16List pcm16) async {
    final whisper = _whisper;
    if (whisper == null) {
      throw StateError('Chưa cài model nhận dạng giọng nói.');
    }
    final floats = Float32List(pcm16.length);
    for (var i = 0; i < pcm16.length; i++) {
      floats[i] = pcm16[i] / 32768.0;
    }
    final result = await whisper.transcribe(
      floats,
      config: const WhisperTranscribeConfig(
        language: 'vi',
        threads: 4,
        noContext: true,
      ),
    );
    return result.text.trim();
  }

  Future<String> answer({
    required String userText,
    required String systemPrompt,
    required List<ChatMessage> previousMessages,
    double temperature = 0.7,
  }) async {
    if (!_llmReady) throw StateError('Chưa nạp model ngôn ngữ.');
    final messages = <ChatMessage>[
      ChatMessage(role: 'system', content: systemPrompt),
      ...previousMessages,
      ChatMessage(role: 'user', content: userText),
    ];
    final answer = StringBuffer();
    await for (final token in _llama.generateChat(
      messages: messages,
      template: 'chatml',
      maxTokens: 256,
      temperature: temperature,
      topP: 0.8,
      topK: 20,
      repeatPenalty: 1.12,
      presencePenalty: 0.2,
    )) {
      answer.write(token);
    }
    return answer
        .toString()
        .replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '')
        .trim();
  }

  Future<void> disposeModels() async {
    await unloadLanguageModel();
    await _whisper?.dispose();
    _whisper = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_llama.dispose());
    unawaited(_whisper?.dispose());
    super.dispose();
  }
}
