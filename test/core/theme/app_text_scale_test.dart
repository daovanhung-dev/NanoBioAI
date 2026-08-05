import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/theme/app_text_scale.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  test('defaults to standard and remains unconfigured', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = await container.read(appTextScaleControllerProvider.future);

    expect(state.preset, AppTextScalePreset.standard);
    expect(state.isConfigured, isFalse);
  });

  test('persists selected preset and onboarding configuration', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(appTextScaleControllerProvider.future);

    await container
        .read(appTextScaleControllerProvider.notifier)
        .select(AppTextScalePreset.veryLarge, markConfigured: true);

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString(AppTextScaleController.presetPreferenceKey),
      AppTextScalePreset.veryLarge.name,
    );
    expect(
      preferences.getBool(AppTextScaleController.configuredPreferenceKey),
      isTrue,
    );
  });

  test('all presets stay inside the approved scale range', () {
    expect(
      AppTextScalePreset.values.map((preset) => preset.factor),
      orderedEquals(<double>[0.90, 1.00, 1.15, 1.30]),
    );
  });
}
