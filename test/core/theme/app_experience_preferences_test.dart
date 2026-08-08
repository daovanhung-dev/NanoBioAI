import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/feedback/app_feedback_policy.dart';
import 'package:nano_app/core/motion/app_motion_policy.dart';
import 'package:nano_app/core/theme/app_experience_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  test(
    'experience preferences start with balanced accessible defaults',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = await container.read(
        appExperiencePreferencesProvider.future,
      );

      expect(state.reduceMotion, isFalse);
      expect(state.hapticsEnabled, isTrue);
      expect(state.soundLevel, AppSoundFeedbackLevel.subtle);
      expect(state.performanceTier, AppPerformanceTier.balanced);
    },
  );

  test('experience choices persist through shared preferences', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(appExperiencePreferencesProvider.future);
    final controller = container.read(
      appExperiencePreferencesProvider.notifier,
    );

    await controller.setReduceMotion(true);
    await controller.setHapticsEnabled(false);
    await controller.setSoundLevel(AppSoundFeedbackLevel.off);
    await controller.setPerformanceTier(AppPerformanceTier.economical);

    final state = container.read(appExperiencePreferencesProvider).value!;
    expect(state.reduceMotion, isTrue);
    expect(state.hapticsEnabled, isFalse);
    expect(state.soundLevel, AppSoundFeedbackLevel.off);
    expect(state.performanceTier, AppPerformanceTier.economical);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('nanobio_reduce_motion'), isTrue);
    expect(preferences.getBool('nanobio_haptics_enabled'), isFalse);
    expect(preferences.getString('nanobio_sound_feedback_level'), 'off');
    expect(
      preferences.getString('nanobio_motion_performance_tier'),
      'economical',
    );
  });

  test('system reduce motion always wins over the local animation choice', () {
    const preferences = AppExperiencePreferences(
      reduceMotion: false,
      performanceTier: AppPerformanceTier.rich,
    );

    final policy = preferences.motionPolicy(systemReduceMotion: true);

    expect(policy.reduceMotion, isTrue);
    expect(policy.performanceTier, AppPerformanceTier.rich);
  });
}
