import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import '../../domain/entities/voice_live_event.dart';
import '../../domain/gateways/voice_audio_gateway.dart';
import '../../domain/gateways/voice_live_gateway.dart';
import 'gemini_live_protocol.dart';
import 'native_voice_audio_gateway.dart';

typedef VoiceLiveWebSocketConnector = Future<WebSocket> Function(Uri uri);
typedef VoiceLiveDebugLogger = void Function(String message);

class GeminiLiveVoiceGateway implements VoiceLiveGateway {
  static const _defaultSetupTimeout = Duration(seconds: 10);
  static const defaultModel = 'gemini-3.1-flash-live-preview';
  static const defaultSystemInstruction =
      'Bạn là Nabi, trợ lý sức khỏe thân thiện của chị Thủy Tiên. '
      'Luôn trò chuyện bằng tiếng Việt, ngắn gọn và rõ ràng. '
      'Không chẩn đoán hoặc thay thế bác sĩ. Khi có dấu hiệu khẩn cấp, '
      'hãy khuyên người dùng liên hệ cơ sở y tế phù hợp ngay.';
  static final Uri _endpoint = Uri.parse(
    'wss://generativelanguage.googleapis.com/ws/'
    'google.ai.generativelanguage.v1beta.GenerativeService.'
    'BidiGenerateContent',
  );

  final String? _apiKey;
  final String _model;
  final String _systemInstruction;
  final VoiceAudioGateway _audio;
  final VoiceLiveWebSocketConnector _connectWebSocket;
  final Duration _setupTimeout;
  final VoiceLiveDebugLogger _debugLog;

  StreamController<VoiceLiveEvent>? _events;
  StreamSubscription<Uint8List>? _inputSubscription;
  StreamSubscription<dynamic>? _socketSubscription;
  WebSocket? _socket;
  String? _resumptionHandle;
  Completer<void>? _setupCompleter;
  int? _setupConnectionGeneration;
  bool _setupComplete = false;
  bool _stopped = true;
  bool _inputPaused = false;
  bool _reconnecting = false;
  int _resumeAttempts = 0;
  int _playbackGeneration = 0;
  int _sessionGeneration = 0;
  int _connectionGeneration = 0;
  Future<void> _playbackTail = Future<void>.value();
  Future<void>? _stopFuture;

  GeminiLiveVoiceGateway({
    required String? apiKey,
    required VoiceAudioGateway audio,
    String model = defaultModel,
    String systemInstruction = defaultSystemInstruction,
    VoiceLiveWebSocketConnector? connectWebSocket,
    Duration setupTimeout = _defaultSetupTimeout,
    VoiceLiveDebugLogger? debugLog,
  }) : assert(setupTimeout > Duration.zero),
       _apiKey = _cleanText(apiKey),
       _model = _cleanText(model) ?? defaultModel,
       _systemInstruction =
           _cleanText(systemInstruction) ?? defaultSystemInstruction,
       _audio = audio,
       _connectWebSocket =
           connectWebSocket ?? ((uri) => WebSocket.connect(uri.toString())),
       _setupTimeout = setupTimeout,
       _debugLog = debugLog ?? _defaultDebugLog;

  @override
  Future<Stream<VoiceLiveEvent>> startSession() async {
    await stopSession();
    final sessionGeneration = ++_sessionGeneration;
    _stopped = false;
    _inputPaused = false;
    _resumeAttempts = 0;
    _resumptionHandle = null;
    _setupComplete = false;
    // A Live session has exactly one owner (the page controller). A single
    // subscription stream queues early setup events until that owner attaches.
    final events = StreamController<VoiceLiveEvent>();
    _events = events;
    final eventStream = events.stream;

    try {
      if (_apiKey == null) {
        throw const VoiceLiveConfigurationException();
      }
      await _audio.prepare();
      _ensureSessionActive(sessionGeneration);

      await _connect(
        sessionGeneration: sessionGeneration,
        resumptionHandle: null,
      );
      _ensureSessionActive(sessionGeneration);

      // Gemini requires setupComplete before any realtime input. Subscribe and
      // open native capture only after _connect has received that acknowledgement.
      _inputSubscription = _audio.inputPcm.listen(
        (pcm) => _sendAudio(pcm, sessionGeneration),
        onError: (Object error, StackTrace _) {
          _diagnoseError(stage: 'audio_input', error: error);
          unawaited(
            _failSession(
              error,
              stage: 'audio_input',
              sessionGeneration: sessionGeneration,
              alreadyDiagnosed: true,
            ),
          );
        },
      );
      await _audio.startCapture();
      _ensureSessionActive(sessionGeneration);

      _emitForSession(const VoiceLiveEvent.connected(), sessionGeneration);
      _emitForSession(const VoiceLiveEvent.listening(), sessionGeneration);
    } on _SessionCancelledException {
      // stopSession already released the resources for this stale start call.
    } on VoiceAudioPermissionDeniedException {
      if (_isSessionActive(sessionGeneration)) {
        _emitForSession(
          const VoiceLiveEvent.permissionDenied(),
          sessionGeneration,
        );
        await _stopSessionIfCurrent(sessionGeneration);
      }
    } catch (error) {
      if (_isSessionActive(sessionGeneration)) {
        _diagnoseError(stage: 'session_start', error: error);
        _emitForSession(VoiceLiveEvent.failure(error), sessionGeneration);
        await _stopSessionIfCurrent(sessionGeneration);
      }
    }

    return eventStream;
  }

  @override
  Future<void> pauseInput() async {
    if (_stopped || _inputPaused) return;
    final sessionGeneration = _sessionGeneration;
    await _audio.pauseCapture();
    if (!_isSessionActive(sessionGeneration)) return;
    _inputPaused = true;
    _sendRealtime(GeminiLiveProtocol.audioStreamEnd, sessionGeneration);
    _emitForSession(const VoiceLiveEvent.paused(), sessionGeneration);
  }

  @override
  Future<void> resumeInput() async {
    if (_stopped || !_inputPaused) return;
    final sessionGeneration = _sessionGeneration;
    await _audio.resumeCapture();
    if (!_isSessionActive(sessionGeneration)) return;
    _inputPaused = false;
    _emitForSession(const VoiceLiveEvent.listening(), sessionGeneration);
  }

  @override
  Future<void> setOutputMuted(bool muted) => _audio.setOutputMuted(muted);

  @override
  Future<void> stopOutputImmediately() {
    _playbackGeneration++;
    return _audio.stopPlayback();
  }

  @override
  Future<void> stopSession() {
    final stopping = _stopFuture;
    if (stopping != null) return stopping;

    late final Future<void> operation;
    operation = _stopSessionImpl();
    _stopFuture = operation;
    return operation.whenComplete(() {
      if (identical(_stopFuture, operation)) _stopFuture = null;
    });
  }

  Future<void> _stopSessionImpl() async {
    if (_stopped && _events == null) return;
    final hadSession = !_stopped || _events != null;
    _sessionGeneration++;
    _connectionGeneration++;
    _stopped = true;
    _inputPaused = false;
    _reconnecting = false;
    _setupComplete = false;
    _completePendingSetup();
    _playbackGeneration++;

    final inputSubscription = _inputSubscription;
    _inputSubscription = null;
    try {
      await inputSubscription?.cancel();
    } catch (error) {
      _diagnoseError(stage: 'audio_input_cancel', error: error);
    }

    final socketSubscription = _socketSubscription;
    _socketSubscription = null;
    try {
      await socketSubscription?.cancel();
    } catch (error) {
      _diagnoseError(stage: 'socket_subscription_cancel', error: error);
    }

    final socket = _socket;
    _socket = null;
    try {
      await socket?.close();
    } catch (error) {
      _diagnoseError(stage: 'socket_close', error: error);
    }

    try {
      await _audio.dispose();
    } catch (error) {
      _diagnoseError(stage: 'audio_dispose', error: error);
    }

    _resumptionHandle = null;
    _resumeAttempts = 0;
    final events = _events;
    _events = null;
    if (hadSession && events != null && !events.isClosed) {
      events.add(const VoiceLiveEvent.closed());
      // A start can be cancelled before its owner receives the stream. Awaiting
      // close on a single-subscription controller would then wait forever for a
      // listener that will never attach.
      unawaited(events.close());
    }
  }

  Future<void> _connect({
    required int sessionGeneration,
    required String? resumptionHandle,
  }) async {
    _ensureSessionActive(sessionGeneration);
    final apiKey = _apiKey;
    if (apiKey == null) throw const VoiceLiveConfigurationException();

    final connectionGeneration = ++_connectionGeneration;
    _setupComplete = false;
    _completePendingSetup();
    final query = <String, String>{'key': apiKey};
    late final WebSocket socket;
    try {
      socket = await _connectWebSocket(
        _endpoint.replace(queryParameters: query),
      );
    } catch (error) {
      _diagnoseError(stage: 'socket_connect', error: error);
      rethrow;
    }

    if (!_isSessionActive(sessionGeneration) ||
        connectionGeneration != _connectionGeneration) {
      await _closeDetachedSocket(socket);
      throw const _SessionCancelledException();
    }

    _socket = socket;
    final setupCompleter = Completer<void>();
    _setupCompleter = setupCompleter;
    _setupConnectionGeneration = connectionGeneration;
    _socketSubscription = socket.listen(
      (raw) => _onSocketMessage(
        raw,
        sessionGeneration: sessionGeneration,
        connectionGeneration: connectionGeneration,
      ),
      onError: (Object error, StackTrace _) {
        _diagnoseError(stage: 'socket_stream', error: error);
        unawaited(
          _handleSocketFailure(
            error,
            stage: 'socket_stream',
            sessionGeneration: sessionGeneration,
            connectionGeneration: connectionGeneration,
            alreadyDiagnosed: true,
          ),
        );
      },
      onDone: () {
        unawaited(
          _handleSocketDone(
            sessionGeneration: sessionGeneration,
            connectionGeneration: connectionGeneration,
            closeCode: socket.closeCode,
          ),
        );
      },
      cancelOnError: true,
    );

    try {
      socket.add(
        jsonEncode(
          GeminiLiveProtocol.setup(
            model: _model,
            systemInstruction: _systemInstruction,
            resumptionHandle: resumptionHandle,
          ),
        ),
      );
    } catch (error) {
      _diagnoseError(stage: 'setup_send', error: error);
      _failPendingSetup(error, connectionGeneration);
      rethrow;
    }

    try {
      await setupCompleter.future.timeout(_setupTimeout);
    } on TimeoutException catch (error) {
      _diagnoseError(stage: 'setup_timeout', error: error);
      rethrow;
    } finally {
      if (identical(_setupCompleter, setupCompleter)) {
        _setupCompleter = null;
        _setupConnectionGeneration = null;
      }
    }

    _ensureSessionActive(sessionGeneration);
    if (connectionGeneration != _connectionGeneration || !_setupComplete) {
      throw const _SessionCancelledException();
    }
  }

  void _onSocketMessage(
    Object? raw, {
    required int sessionGeneration,
    required int connectionGeneration,
  }) {
    if (!_isCurrentConnection(sessionGeneration, connectionGeneration)) return;
    try {
      final message = GeminiLiveProtocol.parse(raw);
      if (message.setupComplete) _completeSetup(connectionGeneration);
      if (message.resumptionAvailable != null) {
        // A non-resumable update invalidates any older handle. Retrying that
        // stale handle after a GoAway/transport close only creates a second
        // avoidable WebSocket failure.
        _resumptionHandle = message.resumptionHandle;
      }
      for (final event in message.events) {
        _handleServerEvent(
          event,
          sessionGeneration: sessionGeneration,
          connectionGeneration: connectionGeneration,
        );
      }
      if (message.goAway) {
        unawaited(
          _resumeSession(
            sessionGeneration: sessionGeneration,
            sourceConnectionGeneration: connectionGeneration,
          ),
        );
      }
    } catch (error) {
      _diagnoseError(stage: 'protocol_parse', error: error);
      unawaited(
        _handleSocketFailure(
          error,
          stage: 'protocol_parse',
          sessionGeneration: sessionGeneration,
          connectionGeneration: connectionGeneration,
          alreadyDiagnosed: true,
        ),
      );
    }
  }

  void _handleServerEvent(
    VoiceLiveEvent event, {
    required int sessionGeneration,
    required int connectionGeneration,
  }) {
    if (!_isCurrentConnection(sessionGeneration, connectionGeneration)) return;
    if (event.type == VoiceLiveEventType.outputAudio && event.audio != null) {
      final audio = event.audio!;
      final playbackGeneration = _playbackGeneration;
      _playbackTail = _playbackTail
          .catchError((Object error) {
            _diagnoseError(stage: 'playback', error: error);
          })
          .then((_) {
            if (!_isCurrentConnection(
                  sessionGeneration,
                  connectionGeneration,
                ) ||
                playbackGeneration != _playbackGeneration) {
              return Future<void>.value();
            }
            return _audio.playPcm(audio);
          });
    }
    if (event.type == VoiceLiveEventType.interrupted) {
      _playbackGeneration++;
      unawaited(_audio.stopPlayback());
    }
    _emitForSession(event, sessionGeneration);
  }

  void _sendAudio(Uint8List pcm, int sessionGeneration) {
    if (pcm.isEmpty || _inputPaused) return;
    _sendRealtime(GeminiLiveProtocol.audio(pcm), sessionGeneration);
  }

  void _sendRealtime(Map<String, Object?> message, int sessionGeneration) {
    if (!_isSessionActive(sessionGeneration) ||
        !_setupComplete ||
        _reconnecting) {
      return;
    }
    final socket = _socket;
    final connectionGeneration = _connectionGeneration;
    if (socket == null || socket.readyState != WebSocket.open) return;
    try {
      socket.add(jsonEncode(message));
    } catch (error) {
      _diagnoseError(stage: 'realtime_send', error: error);
      unawaited(
        _handleSocketFailure(
          error,
          stage: 'realtime_send',
          sessionGeneration: sessionGeneration,
          connectionGeneration: connectionGeneration,
          alreadyDiagnosed: true,
        ),
      );
    }
  }

  Future<void> _handleSocketDone({
    required int sessionGeneration,
    required int connectionGeneration,
    required int? closeCode,
  }) async {
    if (!_isCurrentConnection(sessionGeneration, connectionGeneration)) return;
    _diagnoseClose(stage: 'socket_done', closeCode: closeCode);
    final error = _SocketClosedException(closeCode);
    await _handleSocketFailure(
      error,
      stage: 'socket_done',
      sessionGeneration: sessionGeneration,
      connectionGeneration: connectionGeneration,
      alreadyDiagnosed: true,
    );
  }

  Future<void> _handleSocketFailure(
    Object error, {
    required String stage,
    required int sessionGeneration,
    required int connectionGeneration,
    bool alreadyDiagnosed = false,
  }) async {
    if (!_isCurrentConnection(sessionGeneration, connectionGeneration) ||
        _reconnecting) {
      return;
    }
    if (!alreadyDiagnosed) _diagnoseError(stage: stage, error: error);
    if (_failPendingSetup(error, connectionGeneration)) return;
    if (_resumptionHandle == null) {
      await _failSession(
        error,
        stage: stage,
        sessionGeneration: sessionGeneration,
        alreadyDiagnosed: true,
      );
      return;
    }
    await _resumeSession(
      sessionGeneration: sessionGeneration,
      sourceConnectionGeneration: connectionGeneration,
    );
  }

  Future<void> _resumeSession({
    required int sessionGeneration,
    required int sourceConnectionGeneration,
  }) async {
    if (!_isCurrentConnection(sessionGeneration, sourceConnectionGeneration) ||
        _reconnecting) {
      return;
    }
    final handle = _resumptionHandle;
    if (handle == null) {
      await _failSession(
        StateError('Voice Live session ended.'),
        stage: 'resume_unavailable',
        sessionGeneration: sessionGeneration,
      );
      return;
    }
    if (_resumeAttempts >= 1) {
      await _failSession(
        StateError('Voice Live reconnection failed.'),
        stage: 'resume_attempt_limit',
        sessionGeneration: sessionGeneration,
      );
      return;
    }

    _reconnecting = true;
    _setupComplete = false;
    _completePendingSetup();
    _resumeAttempts++;
    _emitForSession(const VoiceLiveEvent.reconnecting(), sessionGeneration);
    try {
      final socketSubscription = _socketSubscription;
      _socketSubscription = null;
      await socketSubscription?.cancel();
      if (!_isSessionActive(sessionGeneration)) return;

      final socket = _socket;
      _socket = null;
      try {
        await socket?.close();
      } catch (error) {
        _diagnoseError(stage: 'resume_socket_close', error: error);
      }
      _ensureSessionActive(sessionGeneration);

      await _connect(
        sessionGeneration: sessionGeneration,
        resumptionHandle: handle,
      );
      if (!_isSessionActive(sessionGeneration)) return;
      // A successful resumption is a new healthy connection. Keep future
      // provider GoAway rollovers resumable instead of consuming a session-wide
      // retry budget after the first one.
      _resumeAttempts = 0;
      _emitForSession(const VoiceLiveEvent.reconnected(), sessionGeneration);
      _emitForSession(
        _inputPaused
            ? const VoiceLiveEvent.paused()
            : const VoiceLiveEvent.listening(),
        sessionGeneration,
      );
    } on _SessionCancelledException {
      // The page/app ended the session while the reconnect was in flight.
    } catch (error) {
      if (_isSessionActive(sessionGeneration)) {
        _diagnoseError(stage: 'resume_connect', error: error);
        await _failSession(
          error,
          stage: 'resume_connect',
          sessionGeneration: sessionGeneration,
          alreadyDiagnosed: true,
        );
      }
    } finally {
      if (_sessionGeneration == sessionGeneration) _reconnecting = false;
    }
  }

  Future<void> _failSession(
    Object error, {
    required String stage,
    required int sessionGeneration,
    bool alreadyDiagnosed = false,
  }) async {
    if (!_isSessionActive(sessionGeneration)) return;
    if (!alreadyDiagnosed) _diagnoseError(stage: stage, error: error);
    _emitForSession(VoiceLiveEvent.failure(error), sessionGeneration);
    await _stopSessionIfCurrent(sessionGeneration);
  }

  Future<void> _stopSessionIfCurrent(int sessionGeneration) async {
    if (!_isSessionActive(sessionGeneration)) return;
    await stopSession();
  }

  bool _isSessionActive(int sessionGeneration) {
    return !_stopped && _sessionGeneration == sessionGeneration;
  }

  bool _isCurrentConnection(int sessionGeneration, int connectionGeneration) {
    return _isSessionActive(sessionGeneration) &&
        _connectionGeneration == connectionGeneration;
  }

  void _ensureSessionActive(int sessionGeneration) {
    if (!_isSessionActive(sessionGeneration)) {
      throw const _SessionCancelledException();
    }
  }

  void _completeSetup(int connectionGeneration) {
    if (_setupConnectionGeneration != connectionGeneration) return;
    _setupComplete = true;
    final completer = _setupCompleter;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  bool _failPendingSetup(Object error, int connectionGeneration) {
    if (_setupConnectionGeneration != connectionGeneration) return false;
    final completer = _setupCompleter;
    if (completer == null || completer.isCompleted) return false;
    completer.completeError(error);
    return true;
  }

  void _completePendingSetup() {
    final completer = _setupCompleter;
    _setupCompleter = null;
    _setupConnectionGeneration = null;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  Future<void> _closeDetachedSocket(WebSocket socket) async {
    try {
      await socket.close();
    } catch (error) {
      _diagnoseError(stage: 'detached_socket_close', error: error);
    }
  }

  void _emitForSession(VoiceLiveEvent event, int sessionGeneration) {
    if (!_isSessionActive(sessionGeneration)) return;
    final events = _events;
    if (events != null && !events.isClosed) events.add(event);
  }

  void _diagnoseError({required String stage, required Object error}) {
    _debugLog('stage=$stage errorType=${error.runtimeType}');
  }

  void _diagnoseClose({required String stage, required int? closeCode}) {
    _debugLog('stage=$stage closeCode=${closeCode ?? 'none'}');
  }

  static void _defaultDebugLog(String message) {
    developer.log(message, name: 'GeminiLiveVoiceGateway');
  }

  static String? _cleanText(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }
}

class _SessionCancelledException implements Exception {
  const _SessionCancelledException();
}

class _SocketClosedException implements Exception {
  final int? closeCode;

  const _SocketClosedException(this.closeCode);
}
