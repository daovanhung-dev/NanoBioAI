/// Compile-time roots for the Nabi visual asset bundle.
///
/// Static poses and sprite-frame animations live in separate directories so a
/// rollout can switch the complete visual language without changing the
/// animation IDs used by presentation code.
abstract final class NabiAssetCatalog {
  const NabiAssetCatalog._();

  /// Enables the Nabi v2 visual bundle for a build.
  ///
  /// V2 is the release bundle. Pass
  /// `--dart-define=NABI_V2_ASSETS_ENABLED=false` only together with the V1
  /// rollback asset manifest documented in `NABI_V2_ROLLOUT.md`.
  static const bool v2AssetsEnabled = bool.fromEnvironment(
    'NABI_V2_ASSETS_ENABLED',
    defaultValue: true,
  );

  static const String v1StaticRoot = 'assets/images/nabi';
  static const String v2StaticRoot = 'assets/images/nabi_v2';
  static const String v1SpriteRoot = 'assets/nabi';
  static const String v2SpriteRoot = 'assets/nabi_v2';

  static const String staticRoot = v2AssetsEnabled
      ? v2StaticRoot
      : v1StaticRoot;
  static const String spriteRoot = v2AssetsEnabled
      ? v2SpriteRoot
      : v1SpriteRoot;

  /// Resolves a lowercase relative static-pose path against the selected
  /// bundle, for example `core/nabi_idle_happy.png`.
  static String staticAssetPath(String relativePath) =>
      '$staticRoot/$relativePath';

  /// Resolves a sprite-relative path against the selected bundle.
  static String spriteAssetPath(String relativePath) =>
      '$spriteRoot/$relativePath';
}
