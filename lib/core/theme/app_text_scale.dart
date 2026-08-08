import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Four bounded text-size presets shared by every NanoBio app surface.
enum AppTextScalePreset {
  small(label: 'Nhỏ', factor: 0.90),
  standard(label: 'Tiêu chuẩn', factor: 1.00),
  large(label: 'Lớn', factor: 1.15),
  veryLarge(label: 'Rất lớn', factor: 1.30);

  const AppTextScalePreset({required this.label, required this.factor});

  final String label;
  final double factor;

  static AppTextScalePreset fromStorage(String? value) {
    return AppTextScalePreset.values.firstWhere(
      (preset) => preset.name == value,
      orElse: () => AppTextScalePreset.standard,
    );
  }
}

class AppTextScaleState {
  const AppTextScaleState({required this.preset, required this.isConfigured});

  final AppTextScalePreset preset;
  final bool isConfigured;

  AppTextScaleState copyWith({AppTextScalePreset? preset, bool? isConfigured}) {
    return AppTextScaleState(
      preset: preset ?? this.preset,
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }
}

final appTextScaleControllerProvider =
    AsyncNotifierProvider<AppTextScaleController, AppTextScaleState>(
      AppTextScaleController.new,
    );

class AppTextScaleController extends AsyncNotifier<AppTextScaleState> {
  static const presetPreferenceKey = 'nanobio_text_scale_preset';
  static const configuredPreferenceKey = 'nanobio_text_scale_configured';

  @override
  Future<AppTextScaleState> build() async {
    final preferences = await SharedPreferences.getInstance();
    return AppTextScaleState(
      preset: AppTextScalePreset.fromStorage(
        preferences.getString(presetPreferenceKey),
      ),
      isConfigured: preferences.getBool(configuredPreferenceKey) ?? false,
    );
  }

  Future<void> select(
    AppTextScalePreset preset, {
    bool markConfigured = false,
  }) async {
    final current =
        state.value ??
        const AppTextScaleState(
          preset: AppTextScalePreset.standard,
          isConfigured: false,
        );
    final next = current.copyWith(
      preset: preset,
      isConfigured: markConfigured ? true : current.isConfigured,
    );
    state = AsyncData(next);

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(presetPreferenceKey, preset.name);
    if (markConfigured) {
      await preferences.setBool(configuredPreferenceKey, true);
    }
  }

  Future<void> markConfigured() async {
    final current =
        state.value ??
        const AppTextScaleState(
          preset: AppTextScalePreset.standard,
          isConfigured: false,
        );
    state = AsyncData(current.copyWith(isConfigured: true));
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(configuredPreferenceKey, true);
  }
}
