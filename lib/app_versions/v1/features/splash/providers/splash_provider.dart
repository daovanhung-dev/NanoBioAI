import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/providers/voice_dependencies.dart';
import 'package:nano_app/app_versions/v1/features/splash/providers/splash_state.dart';

import '../domain/services/startup_greeting_service.dart';

final startupGreetingServiceProvider = Provider<StartupGreetingService>((ref) {
  return StartupGreetingService(
    ref.watch(textToSpeechGatewayProvider),
    enabled: !kIsWeb,
  );
});

final splashProvider = NotifierProvider<SplashNotifier, SplashStatus>(
  SplashNotifier.new,
);

class SplashNotifier extends Notifier<SplashStatus> {
  @override
  SplashStatus build() {
    return SplashStatus.initial;
  }

  Future<void> initialize() async {
    state = SplashStatus.loading;
  }
}
