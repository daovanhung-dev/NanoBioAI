import 'dart:async';

import '../entities/voice_live_event.dart';

abstract class VoiceLiveGateway {
  Future<Stream<VoiceLiveEvent>> startSession();

  Future<void> pauseInput();

  Future<void> resumeInput();

  Future<void> setOutputMuted(bool muted);

  Future<void> stopOutputImmediately();

  Future<void> stopSession();
}

/// Raised before audio capture when the installed app has no direct Gemini
/// configuration. It deliberately carries no configuration value.
class VoiceLiveConfigurationException implements Exception {
  const VoiceLiveConfigurationException();
}
