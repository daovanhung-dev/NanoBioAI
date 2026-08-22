import 'dart:async';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/gateways/voice_audio_gateway.dart';

class VoiceAudioPermissionDeniedException implements Exception {
  const VoiceAudioPermissionDeniedException();
}

class VoiceAudioUnavailableException implements Exception {
  final String? message;

  const VoiceAudioUnavailableException({this.message});
}

class NativeVoiceAudioGateway implements VoiceAudioGateway {
  static const _methodChannel = MethodChannel(
    'com.nanobioai.app/realtime_voice_audio',
  );
  static const _inputChannel = EventChannel(
    'com.nanobioai.app/realtime_voice_audio/input_pcm',
  );

  late final Stream<Uint8List> _inputPcm = _inputChannel
      .receiveBroadcastStream()
      .where((event) => event is Uint8List)
      .cast<Uint8List>();

  @override
  Stream<Uint8List> get inputPcm => _inputPcm;

  @override
  Future<void> prepare() async {
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      throw const VoiceAudioPermissionDeniedException();
    }
    await _invoke('prepare');
  }

  @override
  Future<void> startCapture() => _invoke('startCapture');

  @override
  Future<void> pauseCapture() => _invoke('pauseCapture');

  @override
  Future<void> resumeCapture() => _invoke('resumeCapture');

  @override
  Future<void> playPcm(Uint8List pcm) => _invoke('playPcm', {'pcm': pcm});

  @override
  Future<void> stopPlayback() => _invoke('stopPlayback');

  @override
  Future<void> setOutputMuted(bool muted) =>
      _invoke('setOutputMuted', {'muted': muted});

  @override
  Future<void> dispose() => _invoke('dispose');

  Future<void> _invoke(String method, [Object? arguments]) async {
    try {
      await _methodChannel.invokeMethod<void>(method, arguments);
    } on PlatformException catch (error) {
      if (error.code == 'permission_denied') {
        throw const VoiceAudioPermissionDeniedException();
      }
      throw VoiceAudioUnavailableException(message: error.message);
    } on MissingPluginException {
      throw const VoiceAudioUnavailableException();
    }
  }
}
