abstract final class NabiFeatureFlags {
  const NabiFeatureFlags._();

  static const spriteMascotEnabled = bool.fromEnvironment(
    'NABI_SPRITE_MASCOT_ENABLED',
    defaultValue: true,
  );
}
