import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart'
    show ChatMessage;
import 'package:opus_codec/opus_codec.dart' as opus_flutter;
import 'package:opus_codec_dart/opus_codec_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_ai_service.dart';
import 'phone_server_lifecycle.dart';
import 'voice_service.dart';

class XiaozhiServer extends ChangeNotifier {
  XiaozhiServer({required this.ai, required this.voice});

  final LocalAiService ai;
  final VoiceService voice;
  HttpServer? _server;
  Timer? _networkMonitor;
  String? _token;
  String? hostAddress;
  String? error;
  List<ServerNetworkAddress> availableAddresses = const [];
  String? selectedAddress;
  WebSocket? _activeSocket;
  final List<ChatMessage> _conversation = [];

  bool get isRunning => _server != null;
  String get otaUrl => 'http://${hostAddress ?? '0.0.0.0'}:8765/xiaozhi/ota/';
  String get websocketUrl =>
      'ws://${hostAddress ?? '0.0.0.0'}:8765/xiaozhi/v1/';

  Future<void> refreshAddresses() async {
    final previousSelection = selectedAddress;
    availableAddresses = await _findLocalIpv4Candidates();
    final matching = availableAddresses
        .where((candidate) => candidate.address == previousSelection)
        .firstOrNull;
    if (matching != null) {
      selectedAddress = matching.address;
    } else if (availableAddresses.length == 1) {
      selectedAddress = availableAddresses.single.address;
    } else {
      selectedAddress = null;
    }
    notifyListeners();
  }

  void selectAddress(String address) {
    if (!availableAddresses.any((candidate) => candidate.address == address)) {
      return;
    }
    selectedAddress = address;
    notifyListeners();
  }

  Future<void> start() async {
    if (isRunning) return;
    error = null;
    if (!ai.llmReady || !ai.whisperReady) {
      error = 'Nạp model ngôn ngữ và Whisper trước khi khởi chạy server.';
      notifyListeners();
      return;
    }
    if (!voice.isReady) {
      error =
          'Chọn một giọng Android TTS trong tab Cài đặt trước khi khởi chạy.';
      notifyListeners();
      return;
    }
    if (!voice.selectedVoiceIsOffline) {
      error = 'Giọng Android TTS đang chọn cần mạng. Chọn voice ngoại tuyến để bảo đảm hội thoại hoạt động khi mất Internet.';
      notifyListeners();
      return;
    }
    try {
      final permissionsGranted =
          await PhoneServerLifecycle.requestServerPermissions();
      if (!permissionsGranted) {
        error =
            'Cần cho phép notification để Android hiển thị trạng thái server.';
        notifyListeners();
        return;
      }
      await refreshAddresses();
      if (availableAddresses.isEmpty) {
        error = 'Không tìm thấy IPv4 nội bộ của hotspot. Bật hotspot rồi thử quét lại.';
        notifyListeners();
        return;
      }
      if (selectedAddress == null) {
        error =
            'Có nhiều địa chỉ mạng. Chọn địa chỉ hotspot của điện thoại trước.';
        notifyListeners();
        return;
      }
      await PhoneServerLifecycle.startForegroundService();
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('server_token');
      if (_token == null || _token!.length < 24) {
        _token = sha256
            .convert(
              utf8.encode(
                '${DateTime.now().microsecondsSinceEpoch}${Random.secure().nextInt(1 << 32)}',
              ),
            )
            .toString();
        await prefs.setString('server_token', _token!);
      }
      hostAddress = selectedAddress;
      await _initializeOpus();
      _server = await HttpServer.bind(
        InternetAddress(hostAddress!),
        8765,
        shared: false,
      );
      _server!.listen(
        _handleRequest,
        onError: (Object value) {
          error = '$value';
          notifyListeners();
        },
      );
      _networkMonitor?.cancel();
      _networkMonitor = Timer.periodic(
        const Duration(seconds: 8),
        (_) => unawaited(_checkBoundAddress()),
      );
      await PhoneServerLifecycle.updateForegroundService(
        'Server AI local đang chạy',
        'OTA: $otaUrl',
      );
    } catch (value) {
      error = '$value';
      await _server?.close(force: true);
      _server = null;
      _networkMonitor?.cancel();
      _networkMonitor = null;
      hostAddress = null;
      await PhoneServerLifecycle.stopForegroundService();
    }
    notifyListeners();
  }

  Future<void> stop() async {
    _networkMonitor?.cancel();
    _networkMonitor = null;
    await _server?.close(force: true);
    _server = null;
    _activeSocket = null;
    await PhoneServerLifecycle.stopForegroundService();
    notifyListeners();
  }

  Future<void> _checkBoundAddress() async {
    if (!isRunning || hostAddress == null) return;
    try {
      final latest = await _findLocalIpv4Candidates();
      availableAddresses = latest;
      if (latest.any((candidate) => candidate.address == hostAddress)) return;
      final previousAddress = hostAddress;
      await _server?.close(force: true);
      _server = null;
      _networkMonitor?.cancel();
      _networkMonitor = null;
      hostAddress = null;
      _activeSocket = null;
      selectedAddress = latest.length == 1 ? latest.single.address : null;
      error = latest.isEmpty
          ? 'Hotspot mất kết nối. Bật lại hotspot, cập nhật OTA URL trên ESP và khởi động lại ESP.'
          : 'Địa chỉ hotspot đã đổi từ $previousAddress. Chọn địa chỉ mới, cập nhật OTA URL trên ESP và khởi động lại ESP.';
      await PhoneServerLifecycle.updateForegroundService(
        'Địa chỉ hotspot đã thay đổi',
        'Cập nhật OTA URL trên ESP rồi khởi động lại ESP.',
      );
      notifyListeners();
    } catch (value) {
      error = 'Không kiểm tra được địa chỉ hotspot: $value';
      notifyListeners();
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (request.uri.path == '/health') {
      final llmReady = ai.llmReady;
      final sttReady = ai.whisperReady;
      final ttsReady = voice.isReady;
      final ttsOffline = voice.selectedVoiceIsOffline;
      request.response
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'ok': llmReady && sttReady && ttsReady && ttsOffline,
            'llm': llmReady,
            'stt': sttReady,
            'tts': ttsReady,
            'tts_offline': ttsOffline,
          }),
        );
      await request.response.close();
      return;
    }
    if (request.uri.path == '/xiaozhi/ota/' ||
        request.uri.path == '/xiaozhi/ota') {
      request.response
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'websocket': {'url': websocketUrl, 'token': _token, 'version': 3},
          }),
        );
      await request.response.close();
      return;
    }
    if (request.uri.path == '/xiaozhi/v1/' ||
        request.uri.path == '/xiaozhi/v1') {
      if (request.headers.value(HttpHeaders.authorizationHeader) !=
          'Bearer $_token') {
        request.response.statusCode = HttpStatus.unauthorized;
        await request.response.close();
        return;
      }
      if (_activeSocket != null &&
          _activeSocket!.readyState == WebSocket.open) {
        request.response.statusCode = HttpStatus.conflict;
        await request.response.close();
        return;
      }
      final socket = await WebSocketTransformer.upgrade(request);
      _activeSocket = socket;
      unawaited(_handleSocket(socket));
      return;
    }
    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }

  Future<void> _handleSocket(WebSocket socket) async {
    final sessionId = Random.secure().nextInt(0x7fffffff).toRadixString(16);
    final pcm = <int>[];
    var decoder = SimpleOpusDecoder(sampleRate: 16000, channels: 1);
    var listening = false;
    Future<void> responseQueue = Future<void>.value();
    socket.listen(
      (event) {
        if (event is String) {
          Map<String, dynamic> message;
          try {
            message = jsonDecode(event) as Map<String, dynamic>;
          } catch (_) {
            return;
          }
          final type = message['type'];
          if (type == 'hello') {
            socket.add(
              jsonEncode({
                'type': 'hello',
                'transport': 'websocket',
                'session_id': sessionId,
                'audio_params': {
                  'format': 'opus',
                  'sample_rate': 24000,
                  'channels': 1,
                  'frame_duration': 60,
                },
              }),
            );
          } else if (type == 'listen' && message['state'] == 'start') {
            listening = true;
            pcm.clear();
          } else if (type == 'listen' &&
              message['state'] == 'stop' &&
              listening) {
            listening = false;
            final audio = Int16List.fromList(pcm);
            pcm.clear();
            responseQueue = responseQueue.then(
              (_) => _respond(socket, sessionId, audio),
            );
          } else if (type == 'abort') {
            listening = false;
            pcm.clear();
          }
        } else if (event is List<int> && listening && event.length >= 4) {
          final bytes = Uint8List.fromList(event);
          final length = ByteData.sublistView(bytes).getUint16(2, Endian.big);
          if (bytes[0] != 0 || length > bytes.length - 4) return;
          final packet = bytes.sublist(4, 4 + length);
          pcm.addAll(decoder.decode(input: packet));
        }
      },
      onDone: () {
        decoder.destroy();
        if (identical(_activeSocket, socket)) _activeSocket = null;
      },
      onError: (_) {
        decoder.destroy();
        if (identical(_activeSocket, socket)) _activeSocket = null;
      },
      cancelOnError: true,
    );
  }

  Future<void> _respond(
    WebSocket socket,
    String sessionId,
    Int16List audio,
  ) async {
    if (socket.readyState != WebSocket.open || audio.isEmpty) return;
    if (!ai.llmReady || !ai.whisperReady) {
      _sendJson(socket, {
        'type': 'alert',
        'status': 'error',
        'message': 'Mở app và nạp model AI + giọng nói trước.',
        'emotion': 'sad',
      });
      return;
    }
    try {
      final recognized = await ai.transcribe(audio);
      if (recognized.isEmpty) return;
      _sendJson(socket, {
        'type': 'stt',
        'text': recognized,
        'session_id': sessionId,
      });
      final answer = await ai.answer(
        userText: recognized,
        systemPrompt: await _systemPrompt(),
        previousMessages: List.of(_conversation),
        temperature: await _temperature(),
      );
      if (answer.isEmpty || socket.readyState != WebSocket.open) return;
      _conversation
        ..add(ChatMessage(role: 'user', content: recognized))
        ..add(ChatMessage(role: 'assistant', content: answer));
      if (_conversation.length > 12) {
        _conversation.removeRange(0, _conversation.length - 12);
      }

      _sendJson(socket, {
        'type': 'llm',
        'emotion': 'neutral',
        'session_id': sessionId,
      });
      _sendJson(socket, {
        'type': 'tts',
        'state': 'start',
        'session_id': sessionId,
      });
      _sendJson(socket, {
        'type': 'tts',
        'state': 'sentence_start',
        'text': answer,
        'session_id': sessionId,
      });
      for (final packet in await voice.synthesizeOpus(answer)) {
        if (socket.readyState != WebSocket.open) break;
        final framed = Uint8List(packet.length + 4);
        framed[0] = 0;
        framed[1] = 0;
        ByteData.sublistView(framed).setUint16(2, packet.length, Endian.big);
        framed.setRange(4, framed.length, packet);
        socket.add(framed);
      }
      _sendJson(socket, {
        'type': 'tts',
        'state': 'stop',
        'session_id': sessionId,
      });
    } catch (value) {
      _sendJson(socket, {
        'type': 'alert',
        'status': 'error',
        'message': 'Lỗi xử lý AI local: $value',
        'emotion': 'sad',
      });
    }
  }

  Future<String> _systemPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString('system_prompt')?.trim() ?? '';
    final language = prefs.getString('response_language') ?? 'vi';
    return [
      'You are a local voice assistant running on the phone. Keep replies concise and natural for speech.',
      if (language == 'vi') 'Trả lời bằng tiếng Việt tự nhiên.',
      if (language == 'en') 'Reply in English.',
      if (language == 'auto') 'Reply in the same language as the user.',
      if (custom.isNotEmpty) custom,
    ].join('\n');
  }

  Future<double> _temperature() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('temperature') ?? 0.7;
  }

  void _sendJson(WebSocket socket, Map<String, Object?> message) {
    if (socket.readyState == WebSocket.open) socket.add(jsonEncode(message));
  }

  Future<List<ServerNetworkAddress>> _findLocalIpv4Candidates() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    final candidates = <ServerNetworkAddress>[];
    for (final interface in interfaces) {
      final name = interface.name.toLowerCase();
      if (name.contains('p2p') ||
          name.contains('vpn') ||
          name.contains('tun') ||
          name.contains('lo')) {
        continue;
      }
      for (final address in interface.addresses) {
        final value = address.address;
        if (!_isPrivateIpv4(value) || address.isLoopback) continue;
        candidates.add(ServerNetworkAddress(interface.name, value));
      }
    }
    candidates.sort((left, right) {
      final byInterface = left.interfaceName.compareTo(right.interfaceName);
      return byInterface != 0
          ? byInterface
          : left.address.compareTo(right.address);
    });
    return candidates;
  }

  bool _isPrivateIpv4(String value) {
    final parts = value.split('.');
    if (parts.length != 4) return false;
    final octets = parts.map(int.tryParse).toList();
    if (octets.any((part) => part == null || part < 0 || part > 255)) {
      return false;
    }
    final first = octets[0]!;
    final second = octets[1]!;
    return first == 10 ||
        first == 192 && second == 168 ||
        first == 172 && second >= 16 && second <= 31;
  }

  Future<void> _initializeOpus() async {
    initOpus(await opus_flutter.load());
  }

  @override
  void dispose() {
    unawaited(stop());
    super.dispose();
  }
}

class ServerNetworkAddress {
  const ServerNetworkAddress(this.interfaceName, this.address);

  final String interfaceName;
  final String address;

  @override
  String toString() => '$address · $interfaceName';
}
