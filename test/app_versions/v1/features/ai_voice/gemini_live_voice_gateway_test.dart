import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/data/gateways/gemini_live_voice_gateway.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/entities/voice_live_event.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/gateways/voice_audio_gateway.dart';

const _directApiKey = 'direct-test-key';

void main() {
  test(
    'waits for setupComplete before opening capture or sending PCM',
    () async {
      final server = await _LiveSocketServer.start(autoSetupComplete: false);
      addTearDown(server.dispose);
      final audio = _FakeVoiceAudioGateway();
      Uri? requestedUri;
      final gateway = GeminiLiveVoiceGateway(
        apiKey: _directApiKey,
        audio: audio,
        connectWebSocket: (uri) {
          requestedUri = uri;
          return WebSocket.connect(server.webSocketUri.toString());
        },
      );
      addTearDown(gateway.stopSession);

      final starting = gateway.startSession();
      final socket = await server.socket;
      await server.waitForClientMessage(
        (message) => message.containsKey('setup'),
      );

      expect(audio.startCaptureCalls, 0);
      audio.emit(Uint8List.fromList(<int>[1, 2]));
      await Future<void>.delayed(Duration.zero);
      expect(server.realtimeInputCount, 0);
      expect(requestedUri!.path, endsWith('BidiGenerateContent'));
      expect(requestedUri!.queryParameters['key'], _directApiKey);
      expect(
        requestedUri!.queryParameters.containsKey('access_token'),
        isFalse,
      );

      socket.add(jsonEncode({'setupComplete': {}}));
      final stream = await starting;
      final subscription = stream.listen((_) {});
      addTearDown(subscription.cancel);
      expect(audio.startCaptureCalls, 1);

      audio.emit(Uint8List.fromList(<int>[3, 4]));
      await _waitUntil(() => server.realtimeInputCount == 1);
    },
  );

  test(
    'interruption flushes native playback and drops queued Live audio',
    () async {
      final server = await _LiveSocketServer.start();
      addTearDown(server.dispose);
      final audio = _FakeVoiceAudioGateway();
      final gateway = GeminiLiveVoiceGateway(
        apiKey: _directApiKey,
        audio: audio,
        connectWebSocket: (_) =>
            WebSocket.connect(server.webSocketUri.toString()),
      );
      addTearDown(gateway.stopSession);

      final events = <VoiceLiveEvent>[];
      final stream = await gateway.startSession();
      final subscription = stream.listen(events.add);
      addTearDown(subscription.cancel);
      final socket = await server.socket;

      socket.add(
        jsonEncode({
          'serverContent': {
            'modelTurn': {
              'parts': [
                {
                  'inlineData': {
                    'data': base64Encode(<int>[1, 2]),
                  },
                },
                {
                  'inlineData': {
                    'data': base64Encode(<int>[3, 4]),
                  },
                },
              ],
            },
          },
        }),
      );
      await _waitUntil(() => audio.played.length == 1);

      socket.add(
        jsonEncode({
          'serverContent': {'interrupted': true},
        }),
      );
      await _waitUntil(() => audio.stopPlaybackCalls == 1);
      audio.releaseFirstPlayback();
      await Future<void>.delayed(Duration.zero);

      expect(audio.played, <Uint8List>[
        Uint8List.fromList(<int>[1, 2]),
      ]);
      expect(
        events.map((event) => event.type),
        contains(VoiceLiveEventType.interrupted),
      );
    },
  );

  test('reconnect waits for setupComplete before sending new PCM', () async {
    final server = await _LiveSocketServer.start(autoSetupComplete: false);
    addTearDown(server.dispose);
    final audio = _FakeVoiceAudioGateway();
    final gateway = GeminiLiveVoiceGateway(
      apiKey: _directApiKey,
      audio: audio,
      connectWebSocket: (_) =>
          WebSocket.connect(server.webSocketUri.toString()),
    );
    addTearDown(gateway.stopSession);

    final firstStart = gateway.startSession();
    final firstSocket = await server.socket;
    await server.waitForSetupCount(1);
    firstSocket.add(jsonEncode({'setupComplete': {}}));
    final events = <VoiceLiveEvent>[];
    final stream = await firstStart;
    final subscription = stream.listen(events.add);
    addTearDown(subscription.cancel);

    final secondSocketFuture = server.nextSocket;
    firstSocket.add(
      jsonEncode({
        'sessionResumptionUpdate': {
          'resumable': true,
          'newHandle': 'resume-handle-1',
        },
      }),
    );
    firstSocket.add(jsonEncode({'goAway': {}}));

    final secondSocket = await secondSocketFuture.timeout(
      const Duration(seconds: 1),
    );
    await server.waitForSetupCount(2);
    final reconnectSetup =
        server.setupMessages.last['setup']! as Map<String, Object?>;
    expect(
      (reconnectSetup['sessionResumption']! as Map<String, Object?>)['handle'],
      'resume-handle-1',
    );

    audio.emit(Uint8List.fromList(<int>[9, 9]));
    await Future<void>.delayed(Duration.zero);
    expect(server.realtimeInputCount, 0);
    expect(
      events.map((event) => event.type),
      contains(VoiceLiveEventType.reconnecting),
    );
    expect(
      events.map((event) => event.type),
      isNot(contains(VoiceLiveEventType.reconnected)),
    );

    secondSocket.add(jsonEncode({'setupComplete': {}}));
    await _waitUntil(
      () => events.any((event) => event.type == VoiceLiveEventType.reconnected),
    );
    audio.emit(Uint8List.fromList(<int>[8, 8]));
    await _waitUntil(() => server.realtimeInputCount == 1);

    // A healthy reconnect resets the per-disconnect retry budget. A later
    // provider rollover should not end a conversation just because one earlier
    // resume already succeeded.
    final thirdSocketFuture = server.socketAt(2);
    secondSocket.add(
      jsonEncode({
        'sessionResumptionUpdate': {
          'resumable': true,
          'newHandle': 'resume-handle-2',
        },
      }),
    );
    secondSocket.add(jsonEncode({'goAway': {}}));
    final thirdSocket = await thirdSocketFuture.timeout(
      const Duration(seconds: 1),
    );
    await server.waitForSetupCount(3);
    final secondReconnectSetup =
        server.setupMessages.last['setup']! as Map<String, Object?>;
    expect(
      (secondReconnectSetup['sessionResumption']!
          as Map<String, Object?>)['handle'],
      'resume-handle-2',
    );
    thirdSocket.add(jsonEncode({'setupComplete': {}}));
    await _waitUntil(
      () =>
          events
              .where((event) => event.type == VoiceLiveEventType.reconnected)
              .length ==
          2,
    );
  });

  test('does not resume with a handle the server made non-resumable', () async {
    final server = await _LiveSocketServer.start(autoSetupComplete: false);
    addTearDown(server.dispose);
    final audio = _FakeVoiceAudioGateway();
    var connectorCalls = 0;
    final gateway = GeminiLiveVoiceGateway(
      apiKey: _directApiKey,
      audio: audio,
      connectWebSocket: (_) {
        connectorCalls++;
        return WebSocket.connect(server.webSocketUri.toString());
      },
    );
    addTearDown(gateway.stopSession);

    final starting = gateway.startSession();
    final socket = await server.socket;
    await server.waitForSetupCount(1);
    socket.add(jsonEncode({'setupComplete': {}}));
    final events = <VoiceLiveEvent>[];
    final stream = await starting;
    final subscription = stream.listen(events.add);
    addTearDown(subscription.cancel);

    socket.add(
      jsonEncode({
        'sessionResumptionUpdate': {
          'resumable': true,
          'newHandle': 'handle-that-will-expire',
        },
      }),
    );
    socket.add(
      jsonEncode({
        'sessionResumptionUpdate': {'resumable': false, 'newHandle': ''},
      }),
    );
    socket.add(jsonEncode({'goAway': {}}));

    await _waitUntil(
      () => events.any((event) => event.type == VoiceLiveEventType.failure),
    );
    expect(connectorCalls, 1);
  });

  test(
    'setup timeout closes audio and logs only redacted diagnostics',
    () async {
      final server = await _LiveSocketServer.start(autoSetupComplete: false);
      addTearDown(server.dispose);
      final audio = _FakeVoiceAudioGateway();
      final diagnostics = <String>[];
      final gateway = GeminiLiveVoiceGateway(
        apiKey: 'super-secret-direct-key',
        audio: audio,
        setupTimeout: const Duration(milliseconds: 20),
        debugLog: diagnostics.add,
        connectWebSocket: (_) =>
            WebSocket.connect(server.webSocketUri.toString()),
      );
      addTearDown(gateway.stopSession);

      final stream = await gateway.startSession();
      final events = await stream.toList();

      expect(audio.startCaptureCalls, 0);
      expect(audio.disposeCalls, 1);
      expect(events.map((event) => event.type), <VoiceLiveEventType>[
        VoiceLiveEventType.failure,
        VoiceLiveEventType.closed,
      ]);
      expect(diagnostics, contains(contains('stage=setup_timeout')));
      expect(diagnostics.join('|'), isNot(contains('super-secret-direct-key')));
    },
  );

  test(
    'missing direct configuration fails before microphone or socket opens',
    () async {
      final audio = _FakeVoiceAudioGateway();
      var connectorCalls = 0;
      final gateway = GeminiLiveVoiceGateway(
        apiKey: null,
        audio: audio,
        connectWebSocket: (_) async {
          connectorCalls++;
          throw StateError('must not connect');
        },
      );
      addTearDown(gateway.stopSession);

      final stream = await gateway.startSession();
      final events = await stream.toList();

      expect(connectorCalls, 0);
      expect(audio.prepareCalls, 0);
      expect(audio.startCaptureCalls, 0);
      expect(audio.disposeCalls, 1);
      expect(events.map((event) => event.type), <VoiceLiveEventType>[
        VoiceLiveEventType.failure,
        VoiceLiveEventType.closed,
      ]);
    },
  );

  test(
    'stop invalidates an in-flight WebSocket connection before capture opens',
    () async {
      final server = await _LiveSocketServer.start();
      addTearDown(server.dispose);
      final connectionStarted = Completer<void>();
      final releaseConnection = Completer<void>();
      final audio = _FakeVoiceAudioGateway();
      var connectorCalls = 0;
      final gateway = GeminiLiveVoiceGateway(
        apiKey: _directApiKey,
        audio: audio,
        connectWebSocket: (_) async {
          connectorCalls++;
          if (!connectionStarted.isCompleted) connectionStarted.complete();
          await releaseConnection.future;
          return WebSocket.connect(server.webSocketUri.toString());
        },
      );
      addTearDown(gateway.stopSession);

      final starting = gateway.startSession();
      await connectionStarted.future;
      await gateway.stopSession();
      releaseConnection.complete();
      final stream = await starting;
      await stream.drain<void>();

      expect(connectorCalls, 1);
      expect(audio.startCaptureCalls, 0);
      expect(audio.disposeCalls, 1);
    },
  );
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out waiting for Live gateway event.');
}

class _FakeVoiceAudioGateway implements VoiceAudioGateway {
  final _input = StreamController<Uint8List>.broadcast();
  final played = <Uint8List>[];
  final _firstPlayback = Completer<void>();
  int prepareCalls = 0;
  int startCaptureCalls = 0;
  int disposeCalls = 0;
  int stopPlaybackCalls = 0;

  @override
  Stream<Uint8List> get inputPcm => _input.stream;

  @override
  Future<void> dispose() async {
    disposeCalls++;
    if (!_input.isClosed) await _input.close();
  }

  void emit(Uint8List pcm) {
    if (!_input.isClosed) _input.add(pcm);
  }

  @override
  Future<void> pauseCapture() async {}

  @override
  Future<void> playPcm(Uint8List pcm) {
    played.add(pcm);
    return played.length == 1 ? _firstPlayback.future : Future<void>.value();
  }

  void releaseFirstPlayback() {
    if (!_firstPlayback.isCompleted) _firstPlayback.complete();
  }

  @override
  Future<void> prepare() async {
    prepareCalls++;
  }

  @override
  Future<void> resumeCapture() async {}

  @override
  Future<void> setOutputMuted(bool muted) async {}

  @override
  Future<void> startCapture() async {
    startCaptureCalls++;
  }

  @override
  Future<void> stopPlayback() async {
    stopPlaybackCalls++;
  }
}

class _LiveSocketServer {
  _LiveSocketServer._(this._server, this._autoSetupComplete);

  final HttpServer _server;
  final bool _autoSetupComplete;
  final _socketCompleter = Completer<WebSocket>();
  final _nextSocketCompleter = Completer<WebSocket>();
  final sockets = <WebSocket>[];
  final clientMessages = <Map<String, Object?>>[];

  Uri get webSocketUri => Uri(
    scheme: 'ws',
    host: InternetAddress.loopbackIPv4.address,
    port: _server.port,
  );

  Future<WebSocket> get socket => _socketCompleter.future;
  Future<WebSocket> get nextSocket => _nextSocketCompleter.future;

  Future<WebSocket> socketAt(int index) async {
    await _waitUntil(() => sockets.length > index);
    return sockets[index];
  }

  List<Map<String, Object?>> get setupMessages => clientMessages
      .where((message) => message.containsKey('setup'))
      .toList(growable: false);
  int get realtimeInputCount => clientMessages
      .where((message) => message.containsKey('realtimeInput'))
      .length;

  static Future<_LiveSocketServer> start({
    bool autoSetupComplete = true,
  }) async {
    final httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final server = _LiveSocketServer._(httpServer, autoSetupComplete);
    unawaited(
      httpServer.forEach((request) async {
        final socket = await WebSocketTransformer.upgrade(request);
        server._trackSocket(socket);
      }),
    );
    return server;
  }

  void _trackSocket(WebSocket socket) {
    sockets.add(socket);
    if (!_socketCompleter.isCompleted) {
      _socketCompleter.complete(socket);
    } else if (!_nextSocketCompleter.isCompleted) {
      _nextSocketCompleter.complete(socket);
    }
    socket.listen((raw) {
      if (raw is! String) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final message = Map<String, Object?>.fromEntries(
        decoded.entries.map(
          (entry) => MapEntry(entry.key.toString(), entry.value),
        ),
      );
      clientMessages.add(message);
      if (_autoSetupComplete && message.containsKey('setup')) {
        socket.add(jsonEncode({'setupComplete': {}}));
      }
    });
  }

  Future<Map<String, Object?>> waitForClientMessage(
    bool Function(Map<String, Object?> message) predicate,
  ) async {
    await _waitUntil(() => clientMessages.any(predicate));
    return clientMessages.firstWhere(predicate);
  }

  Future<void> waitForSetupCount(int count) {
    return _waitUntil(() => setupMessages.length >= count);
  }

  Future<void> dispose() async {
    for (final socket in sockets) {
      await socket.close();
    }
    await _server.close(force: true);
  }
}
