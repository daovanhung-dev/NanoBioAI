import 'dart:typed_data';

enum VoiceLiveEventType {
  connected,
  listening,
  inputTranscript,
  outputTranscript,
  outputAudio,
  interrupted,
  turnCompleted,
  paused,
  reconnecting,
  reconnected,
  permissionDenied,
  failure,
  closed,
}

class VoiceLiveEvent {
  final VoiceLiveEventType type;
  final String transcript;
  final Uint8List? audio;
  final Object? error;

  const VoiceLiveEvent._({
    required this.type,
    this.transcript = '',
    this.audio,
    this.error,
  });

  const VoiceLiveEvent.connected() : this._(type: VoiceLiveEventType.connected);
  const VoiceLiveEvent.listening() : this._(type: VoiceLiveEventType.listening);
  const VoiceLiveEvent.inputTranscript(String transcript)
    : this._(type: VoiceLiveEventType.inputTranscript, transcript: transcript);
  const VoiceLiveEvent.outputTranscript(String transcript)
    : this._(type: VoiceLiveEventType.outputTranscript, transcript: transcript);
  VoiceLiveEvent.outputAudio(Uint8List audio)
    : this._(type: VoiceLiveEventType.outputAudio, audio: audio);
  const VoiceLiveEvent.interrupted()
    : this._(type: VoiceLiveEventType.interrupted);
  const VoiceLiveEvent.turnCompleted()
    : this._(type: VoiceLiveEventType.turnCompleted);
  const VoiceLiveEvent.paused() : this._(type: VoiceLiveEventType.paused);
  const VoiceLiveEvent.reconnecting()
    : this._(type: VoiceLiveEventType.reconnecting);
  const VoiceLiveEvent.reconnected()
    : this._(type: VoiceLiveEventType.reconnected);
  const VoiceLiveEvent.permissionDenied()
    : this._(type: VoiceLiveEventType.permissionDenied);
  const VoiceLiveEvent.failure(Object error)
    : this._(type: VoiceLiveEventType.failure, error: error);
  const VoiceLiveEvent.closed() : this._(type: VoiceLiveEventType.closed);
}
