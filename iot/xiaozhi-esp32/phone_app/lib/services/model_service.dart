import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../models/local_model.dart';

class ModelService extends ChangeNotifier {
  ModelService() : _client = http.Client();

  final http.Client _client;
  String? modelPath;
  List<String> availableModels = [];
  bool downloading = false;
  double downloadProgress = 0;
  String? status;
  String? error;
  StreamSubscription<List<int>>? _downloadSubscription;
  Completer<void>? _abortRequest;
  Completer<void>? _streamFinished;
  IOSink? _sink;
  bool _cancelDownload = false;

  bool get hasModel => modelPath != null && File(modelPath!).existsSync();

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    await _refreshAvailableModels();
    final savedPath = prefs.getString('llm_model_path');
    if (savedPath != null && availableModels.contains(savedPath)) {
      modelPath = savedPath;
      status = 'Đã chọn model ${_basename(savedPath)}';
    } else if (availableModels.isNotEmpty) {
      modelPath = availableModels.first;
      await prefs.setString('llm_model_path', modelPath!);
      status = 'Đã chọn model ${_basename(modelPath!)}';
    }
    notifyListeners();
  }

  String? installedPathFor(LocalModel model) {
    final fileName = '${model.id}.gguf';
    for (final path in availableModels) {
      if (_basename(path) == fileName) return path;
    }
    return null;
  }

  Future<void> selectModel(String path) async {
    if (!availableModels.contains(path) || !await File(path).exists()) {
      throw FileSystemException('Không tìm thấy model đã cài.', path);
    }
    await _saveModel(path);
    status = 'Đã chọn model ${_basename(path)}';
    error = null;
    notifyListeners();
  }

  Future<void> chooseExistingModel() async {
    error = null;
    final selection = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['gguf'],
      dialogTitle: 'Chọn model GGUF đã có trên điện thoại',
    );
    final selected = selection?.path;
    if (selected == null) return;

    final source = File(selected);
    if (!await source.exists() || await source.length() < 1024 * 1024) {
      error = 'File model không hợp lệ hoặc quá nhỏ.';
      notifyListeners();
      return;
    }
    final directory = await _modelsDirectory();
    final destination = File(
      '${directory.path}/${_safeName(_basename(selected))}',
    );
    if (source.path != destination.path) {
      await source.copy(destination.path);
    }
    await _refreshAvailableModels();
    await _saveModel(destination.path);
    status = 'Đã nhập ${_basename(destination.path)}';
    notifyListeners();
  }

  Future<void> download(LocalModel model) async {
    if (downloading) return;
    downloading = true;
    error = null;
    status = 'Đang tải ${model.name}';
    downloadProgress = 0;
    _cancelDownload = false;
    notifyListeners();

    final directory = await _modelsDirectory();
    final destination = File('${directory.path}/${model.id}.gguf');
    final partial = File('${destination.path}.part');
    try {
      _abortRequest = Completer<void>();
      final request = http.AbortableRequest(
        'GET',
        model.url,
        abortTrigger: _abortRequest!.future,
      );
      request.headers['User-Agent'] = 'XiaoZhiLocalAI/1.0';
      final response = await _client.send(request);
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Tải model thất bại (HTTP ${response.statusCode}).',
        );
      }
      final expectedLength = response.contentLength ?? model.sizeBytes;
      var received = 0;
      _streamFinished = Completer<void>();
      _sink = partial.openWrite();
      _downloadSubscription = response.stream.listen(
        (chunk) {
          if (_cancelDownload) return;
          _sink!.add(chunk);
          received += chunk.length;
          downloadProgress = expectedLength <= 0
              ? 0
              : (received / expectedLength).clamp(0.0, 1.0);
          notifyListeners();
        },
        onError: (Object value, StackTrace stack) {
          if (_cancelDownload) {
            if (!_streamFinished!.isCompleted) _streamFinished!.complete();
          } else if (!_streamFinished!.isCompleted) {
            _streamFinished!.completeError(value, stack);
          }
        },
        cancelOnError: true,
        onDone: () {
          if (!_streamFinished!.isCompleted) _streamFinished!.complete();
        },
      );
      await _streamFinished!.future;
      await _sink!.flush();
      await _sink!.close();
      _sink = null;
      if (_cancelDownload) {
        await partial.delete().catchError((_) => partial);
        status = 'Đã hủy tải model';
        return;
      }
      final length = await partial.length();
      if (length < 1024 * 1024) {
        throw const FormatException('File model tải về không đầy đủ.');
      }
      if (model.sha256 != null) {
        final actual = await sha256.bind(partial.openRead()).first;
        if (actual.toString().toLowerCase() != model.sha256!.toLowerCase()) {
          throw const FormatException('SHA-256 model không khớp.');
        }
      }
      if (await destination.exists()) await destination.delete();
      await partial.rename(destination.path);
      await _refreshAvailableModels();
      await _saveModel(destination.path);
      status = 'Đã tải và chọn ${model.name}';
    } catch (value) {
      await _sink?.close();
      _sink = null;
      if (_cancelDownload) {
        await partial.delete().catchError((_) => partial);
        error = null;
        status = 'Đã hủy tải model';
      } else {
        error = '$value';
        status = 'Tải model lỗi';
      }
    } finally {
      downloading = false;
      _downloadSubscription = null;
      _abortRequest = null;
      _streamFinished = null;
      notifyListeners();
    }
  }

  Future<void> cancelDownload() async {
    if (!downloading) return;
    _cancelDownload = true;
    if (_abortRequest case final abort?) {
      if (!abort.isCompleted) abort.complete();
    }
    if (_streamFinished case final finished?) {
      if (!finished.isCompleted) finished.complete();
    }
  }

  Future<void> clearSelection() async {
    modelPath = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('llm_model_path');
    status = 'Chưa chọn model';
    notifyListeners();
  }

  Future<void> _saveModel(String path) async {
    modelPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('llm_model_path', path);
  }

  Future<Directory> _modelsDirectory() async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/models');
    await directory.create(recursive: true);
    return directory;
  }

  Future<void> _refreshAvailableModels() async {
    final directory = await _modelsDirectory();
    availableModels =
        (await directory
              .list()
              .where(
                (entry) =>
                    entry is File && entry.path.toLowerCase().endsWith('.gguf'),
              )
              .map((entry) => entry.path)
              .toList())
          ..sort();
  }

  String _basename(String path) => path.split(Platform.pathSeparator).last;
  String _safeName(String name) =>
      name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

  @override
  void dispose() {
    unawaited(_downloadSubscription?.cancel());
    _client.close();
    super.dispose();
  }
}
