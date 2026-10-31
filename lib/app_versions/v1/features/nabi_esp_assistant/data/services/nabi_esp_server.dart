import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:opus_codec/opus_codec.dart' as opus_flutter;
import 'package:opus_codec_dart/opus_codec_dart.dart';

import 'nabi_esp_audio_frames.dart';
import 'nabi_esp_contract.g.dart';
import 'nabi_esp_voice_pipeline.dart';

typedef NabiEspTurnProcessor =
    Future<NabiEspAssistantReply?> Function(Int16List pcm16);

/// HTTP and WebSocket v3 host for a single XiaoZhi device.
class NabiEspServer {
  NabiEspServer({
    this.port = NabiEspContract.port,
    String? deviceKey,
    Future<void> Function()? initializeCodec,
  }) : _deviceKey = deviceKey,
       _initializeCodec = initializeCodec ?? _initializeOpus;

  static const _maximumAudioSamples = 16000 * 60;
  static const _maximumControlIdLength = 64;
  static const _controlTimeout = Duration(seconds: 5);

  final int port;
  final Future<void> Function() _initializeCodec;
  String? _deviceKey;
  HttpServer? _server;
  WebSocket? _activeSocket;
  bool _socketHandshakePending = false;
  String? _token;
  NabiEspTurnProcessor? _processTurn;
  ValueChanged<String>? _onStateChanged;
  final Map<String, Completer<String?>> _pendingControls = {};
  Future<void> _responseTail = Future<void>.value();
  int? _boundPort;
  String? hostAddress;

  bool get isRunning => _server != null;
  bool get isDeviceConnected => _activeSocket?.readyState == WebSocket.open;
  String get otaUrl =>
      NabiEspContract.otaUrl(hostAddress ?? '0.0.0.0', portOverride: _port);
  String get websocketUrl => NabiEspContract.websocketUrl(
    hostAddress ?? '0.0.0.0',
    portOverride: _port,
  );
  int get _port => _boundPort ?? port;

  void setDeviceKey(String deviceKey) {
    if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(deviceKey)) {
      throw ArgumentError.value(deviceKey, 'deviceKey');
    }
    _deviceKey = deviceKey;
  }

  Future<void> start({
    required InternetAddress bindAddress,
    required NabiEspTurnProcessor processTurn,
    required ValueChanged<String> onStateChanged,
  }) async {
    if (isRunning) return;
    await _initializeCodec();
    hostAddress = bindAddress.address;
    _token = _newToken();
    _processTurn = processTurn;
    _onStateChanged = onStateChanged;
    try {
      final server = await HttpServer.bind(bindAddress, port, shared: false);
      _server = server;
      _boundPort = server.port;
      server.listen(
        (request) => unawaited(_handleRequest(request)),
        onError: (_) => _onStateChanged?.call('error'),
        cancelOnError: false,
      );
    } catch (_) {
      _clearConfiguration();
      rethrow;
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    final socket = _activeSocket;
    _activeSocket = null;
    if (socket != null && socket.readyState == WebSocket.open) {
      await socket.close(WebSocketStatus.goingAway, 'Server stopped');
    }
    for (final control in _pendingControls.values) {
      if (!control.isCompleted) control.complete(null);
    }
    _pendingControls.clear();
    _onStateChanged?.call('stopped');
    _clearConfiguration();
  }

  Future<String?> sendListenControl(String action) async {
    if (action != 'listen.start' && action != 'listen.stop') {
      throw ArgumentError.value(action, 'action');
    }
    final socket = _activeSocket;
    if (socket == null || socket.readyState != WebSocket.open) return null;
    final id = Random.secure().nextInt(0x7fffffff).toRadixString(16);
    final completer = Completer<String?>();
    _pendingControls[id] = completer;
    socket.add(
      jsonEncode({'type': 'nabi.control', 'request_id': id, 'action': action}),
    );
    try {
      return await completer.future.timeout(_controlTimeout);
    } on TimeoutException {
      return null;
    } finally {
      _pendingControls.remove(id);
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (request.uri.path == '/health') {
      await _respondJson(request.response, {
        'ok': isRunning,
        'llm': isRunning,
        'stt': isRunning,
        'tts': isRunning,
        'tts_offline': isRunning,
        'protocol': NabiEspContract.protocolVersion,
      });
      return;
    }
    if (request.uri.path == NabiEspContract.otaPath ||
        request.uri.path ==
            NabiEspContract.otaPath.replaceFirst(RegExp(r'/$'), '')) {
      final suppliedKey =
          request.headers.value(NabiEspContract.deviceKeyHeader) ?? '';
      if (!nabiEspTokensMatch(_deviceKey ?? '', suppliedKey)) {
        request.response.statusCode = HttpStatus.unauthorized;
        await request.response.close();
        return;
      }
      await _respondJson(request.response, {
        'websocket': {
          'url': websocketUrl,
          'token': _token,
          'version': NabiEspContract.protocolVersion,
        },
      });
      return;
    }
    if (request.uri.path == NabiEspContract.websocketPath ||
        request.uri.path ==
            NabiEspContract.websocketPath.replaceFirst(RegExp(r'/$'), '')) {
      final authorization = request.headers.value(
        HttpHeaders.authorizationHeader,
      );
      final suppliedToken = authorization?.startsWith('Bearer ') == true
          ? authorization!.substring(7)
          : '';
      if (!nabiEspTokensMatch(_token ?? '', suppliedToken)) {
        request.response.statusCode = HttpStatus.unauthorized;
        await request.response.close();
        return;
      }
      if (isDeviceConnected || _socketHandshakePending) {
        request.response.statusCode = HttpStatus.conflict;
        await request.response.close();
        return;
      }
      _socketHandshakePending = true;
      try {
        final socket = await WebSocketTransformer.upgrade(request);
        _activeSocket = socket;
        _onStateChanged?.call('connected');
        unawaited(_handleSocket(socket));
      } finally {
        _socketHandshakePending = false;
      }
      return;
    }
    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }

  Future<void> _handleSocket(WebSocket socket) async {
    final sessionId = Random.secure().nextInt(0x7fffffff).toRadixString(16);
    final decodedSamples = <int>[];
    final decoder = SimpleOpusDecoder(sampleRate: 16000, channels: 1);
    var listening = false;
    var overLimit = false;

    socket.listen(
      (event) {
        if (event is String) {
          _handleJsonMessage(
            socket,
            event,
            sessionId,
            onListenStarted: () {
              listening = true;
              overLimit = false;
              decodedSamples.clear();
              _onStateChanged?.call('listening');
            },
            onListenStopped: () {
              if (!listening) return;
              listening = false;
              _onStateChanged?.call('processing');
              if (overLimit) {
                decodedSamples.clear();
                _sendJson(socket, {
                  'type': 'alert',
                  'status': 'error',
                  'message': 'Lượt nghe vượt quá giới hạn 60 giây.',
                  'emotion': 'sad',
                });
                return;
              }
              final audio = Int16List.fromList(decodedSamples);
              decodedSamples.clear();
              _responseTail = _responseTail
                  .then((_) => _respond(socket, sessionId, audio))
                  .catchError((Object _) {});
            },
            onAbort: () {
              listening = false;
              overLimit = false;
              decodedSamples.clear();
              _onStateChanged?.call('connected');
            },
          );
          return;
        }
        if (event is List<int> && listening && !overLimit) {
          try {
            final packet = NabiEspAudioFrames.decode(Uint8List.fromList(event));
            final samples = decoder.decode(input: packet);
            if (decodedSamples.length + samples.length > _maximumAudioSamples) {
              overLimit = true;
              decodedSamples.clear();
              return;
            }
            decodedSamples.addAll(samples);
          } on FormatException {
            // Discard malformed frames without recording their contents.
          } catch (_) {
            // A corrupt packet must not terminate the whole assistant service.
          }
        }
      },
      onDone: () {
        decoder.destroy();
        _completeControls();
        if (identical(_activeSocket, socket)) _activeSocket = null;
        _onStateChanged?.call('disconnected');
      },
      onError: (_) {
        decoder.destroy();
        _completeControls();
        if (identical(_activeSocket, socket)) _activeSocket = null;
        _onStateChanged?.call('disconnected');
      },
      cancelOnError: true,
    );
  }

  void _handleJsonMessage(
    WebSocket socket,
    String raw,
    String sessionId, {
    required VoidCallback onListenStarted,
    required VoidCallback onListenStopped,
    required VoidCallback onAbort,
  }) {
    if (raw.length > 4096) return;
    Map<String, dynamic> message;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      message = decoded;
    } catch (_) {
      return;
    }
    switch (message['type']) {
      case 'hello':
        _sendJson(socket, {
          'type': 'hello',
          'transport': 'websocket',
          'session_id': sessionId,
          'audio_params': {
            'format': 'opus',
            'sample_rate': 24000,
            'channels': 1,
            'frame_duration': 60,
          },
        });
      case 'listen':
        if (message['state'] == 'start') {
          onListenStarted();
        } else if (message['state'] == 'stop') {
          onListenStopped();
        }
      case 'abort':
        onAbort();
      case 'nabi.control_ack':
        final requestId = message['request_id'];
        if (requestId is! String ||
            requestId.length > _maximumControlIdLength) {
          return;
        }
        final pending = _pendingControls.remove(requestId);
        if (pending != null && !pending.isCompleted) {
          final state = message['state'];
          pending.complete(
            message['ok'] == true && state is String ? state : null,
          );
        }
    }
  }

  Future<void> _respond(
    WebSocket socket,
    String sessionId,
    Int16List audio,
  ) async {
    if (socket.readyState != WebSocket.open || audio.isEmpty) return;
    try {
      final reply = await _processTurn?.call(audio);
      if (reply == null || socket.readyState != WebSocket.open) {
        _onStateChanged?.call('connected');
        return;
      }
      _sendJson(socket, {
        'type': 'stt',
        'text': reply.transcript,
        'session_id': sessionId,
      });
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
        'text': reply.text,
        'session_id': sessionId,
      });
      _onStateChanged?.call('speaking');
      for (final packet in reply.opusPackets) {
        if (socket.readyState != WebSocket.open) break;
        socket.add(NabiEspAudioFrames.encode(packet));
      }
      _sendJson(socket, {
        'type': 'tts',
        'state': 'stop',
        'session_id': sessionId,
      });
    } catch (_) {
      _sendJson(socket, {
        'type': 'alert',
        'status': 'error',
        'message': 'Không xử lý được lượt nói qua máy chủ AI NanoBio.',
        'emotion': 'sad',
      });
    } finally {
      if (socket.readyState == WebSocket.open) {
        _onStateChanged?.call('connected');
      }
    }
  }

  void _completeControls() {
    for (final control in _pendingControls.values) {
      if (!control.isCompleted) control.complete(null);
    }
    _pendingControls.clear();
  }

  Future<void> _respondJson(
    HttpResponse response,
    Map<String, Object?> body,
  ) async {
    response
      ..headers.contentType = ContentType.json
      ..headers.set(HttpHeaders.cacheControlHeader, 'no-store')
      ..write(jsonEncode(body));
    await response.close();
  }

  void _sendJson(WebSocket socket, Map<String, Object?> message) {
    if (socket.readyState == WebSocket.open) socket.add(jsonEncode(message));
  }

  String _newToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static Future<void> _initializeOpus() async {
    initOpus(await opus_flutter.load());
  }

  void _clearConfiguration() {
    hostAddress = null;
    _boundPort = null;
    _token = null;
    _deviceKey = null;
    _processTurn = null;
    _onStateChanged = null;
  }
}
