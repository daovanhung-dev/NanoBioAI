class SleepSafetyRuntimeConfig {
  const SleepSafetyRuntimeConfig({
    required this.enabled,
    required this.maxDispatchesPerHour,
    this.eventFreshnessSeconds = 600,
    this.phoneFallbackEnabled = false,
  });

  final bool enabled;
  final int maxDispatchesPerHour;
  final int eventFreshnessSeconds;
  final bool phoneFallbackEnabled;
}
