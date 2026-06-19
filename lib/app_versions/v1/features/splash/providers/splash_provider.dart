import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/splash/providers/splash_state.dart';

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
