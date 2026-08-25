import 'package:nano_app/core/config/app_env.dart';

abstract final class NabiFeatureFlags {
  static const bool spriteMascotEnabled = bool.fromEnvironment(
    'NABI_SPRITE_MASCOT_ENABLED',
    defaultValue: true,
  );

  static final bool nabiEnabled =
      _getBoolFromEnvironment('NABI_ENABLED') ?? true;
  static final bool globalOverlayEnabled =
      _getBoolFromEnvironment('NABI_GLOBAL_OVERLAY_ENABLED') ?? true;
  static final bool proactiveVNextEnabled =
      _getBoolFromEnvironment('NABI_PROACTIVE_VNEXT') ?? false;
  static final bool aiCareEnabled = AppEnv.boolValue(
    'NABI_AI_CARE_ENABLED',
    defaultValue: const bool.fromEnvironment('NABI_AI_CARE_ENABLED'),
  );
  static final String policyMode =
      _firstNonEmpty(const [String.fromEnvironment('NABI_POLICY_MODE')]) ??
      'shadow';
  static final String rolloutAudience =
      _firstNonEmpty(const [String.fromEnvironment('NABI_ROLLOUT_AUDIENCE')]) ??
      'internal';
  static final String rolloutPercent =
      _firstNonEmpty(const [String.fromEnvironment('NABI_ROLLOUT_PERCENT')]) ??
      '0';
  static final String localNotificationGatewayMode =
      _firstNonEmpty(const [
        String.fromEnvironment('NABI_LOCAL_NOTIFICATION_GATEWAY_MODE'),
      ]) ??
      'disabled';

  static bool? _getBoolFromEnvironment(String key) {
    switch (key) {
      case 'NABI_ENABLED':
        return const bool.fromEnvironment('NABI_ENABLED');
      case 'NABI_GLOBAL_OVERLAY_ENABLED':
        return const bool.fromEnvironment('NABI_GLOBAL_OVERLAY_ENABLED');
      case 'NABI_PROACTIVE_VNEXT':
        return const bool.fromEnvironment('NABI_PROACTIVE_VNEXT');
      case 'NABI_AI_CARE_ENABLED':
        return const bool.fromEnvironment('NABI_AI_CARE_ENABLED');
      default:
        return null;
    }
  }

  static String? _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}
