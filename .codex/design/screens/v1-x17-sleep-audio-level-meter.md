# V1-X17 — Sleep Safety Audio Level Meter

- Classification: `embedded-widget` · Group: `07_health_tracking`
- Source: `lib/app_versions/v1/features/sleep_tracking/presentation/widgets/sleep_safety_audio_level_meter.dart`
- Entry: embedded in Sleep Tracking safety setup.
- Job: help the user assess whether the configured sound threshold is useful.
- States: idle, measuring, threshold reached and unavailable/error as provided by widget inputs.
- Design: label the measurement and threshold in text, use a calm semantic meter, avoid persistent pulse and respect reduced motion.
- Guardrail: preserve microphone permission/audio lifecycle and do not persist a threshold from meter animation alone.
- Verification: radius tokens adopted; widget render and permission-state fixtures pending.
