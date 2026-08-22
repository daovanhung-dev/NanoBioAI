import 'dart:async';
import 'dart:typed_data';

abstract class VoiceAudioGateway {
  Stream<Uint8List> get inputPcm;

  Future<void> prepare();

  Future<void> startCapture();

  Future<void> pauseCapture();

  Future<void> resumeCapture();

  Future<void> playPcm(Uint8List pcm);

  Future<void> stopPlayback();

  Future<void> setOutputMuted(bool muted);

  Future<void> dispose();
}
