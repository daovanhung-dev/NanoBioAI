import 'package:flutter/material.dart';

import '../../domain/entities/nabi_expression.dart';
import '../../domain/nabi_animation_type.dart';
import 'nabi_animation_player.dart';

/// Compatibility renderer for the shared Nabi mascot.
///
/// The original Canvas implementation drew a humanoid character locally,
/// which allowed this overlay to drift away from the Nabi asset library. This
/// wrapper intentionally keeps the public [NabiCharacter] API while routing
/// every emotion through [NabiAnimationPlayer] and its selected asset catalog.
/// That means the same Nabi v2 bundle is used wherever the compatibility
/// overlay is mounted, including its reduced-motion first-frame fallback.
class NabiCharacter extends StatelessWidget {
  const NabiCharacter({
    required this.emotion,
    super.key,
    this.size = 92,
    this.minimized = false,
    this.primaryColor,
    this.secondaryColor,
  });

  final NabiEmotion emotion;
  final double size;
  final bool minimized;

  /// Retained for source compatibility with callers of the former Canvas
  /// renderer. Catalog artwork owns Nabi's palette so it is not tinted.
  final Color? primaryColor;

  /// Retained for source compatibility with callers of the former Canvas
  /// renderer. Catalog artwork owns Nabi's palette so it is not tinted.
  final Color? secondaryColor;

  /// Converts the presentation-only emotion API to the stable animation IDs.
  ///
  /// The legacy negative animation IDs deliberately resolve to gentle visual
  /// states in the catalog. No business state or controller behavior changes
  /// at this compatibility boundary.
  static NabiAnimationType animationFor(NabiEmotion emotion) {
    return switch (emotion) {
      NabiEmotion.idle => NabiAnimationType.idle,
      NabiEmotion.greeting => NabiAnimationType.greeting,
      NabiEmotion.listening => NabiAnimationType.listening,
      NabiEmotion.thinking => NabiAnimationType.thinking,
      NabiEmotion.encouraging => NabiAnimationType.happy,
      NabiEmotion.happy => NabiAnimationType.happy,
      NabiEmotion.celebrating => NabiAnimationType.cheering,
      NabiEmotion.concerned => NabiAnimationType.error,
      NabiEmotion.sleepy => NabiAnimationType.reminder,
    };
  }

  @override
  Widget build(BuildContext context) {
    return NabiAnimationPlayer(
      animationType: animationFor(emotion),
      size: size,
      fallbackIcon: Icon(
        Icons.spa_rounded,
        size: size * 0.42,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
