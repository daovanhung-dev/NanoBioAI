import 'dart:ui';

import 'package:flutter/material.dart';

import '../feedback/app_feedback_service.dart';
import '../motion/app_motion_scope.dart';
import 'app_semantic_colors.dart';
import 'app_experience_preferences.dart';
import 'medical_ui.dart';

/// App-level UX wrapper shared by V1, V2, V3, Admin and Sale surfaces.
class AppExperience {
  const AppExperience._();

  static Widget builder(BuildContext context, Widget? child) {
    return builderWithTextScale(
      context,
      child,
      presetFactor: 1,
      preferences: AppExperiencePreferences.defaults,
    );
  }

  static Widget builderWithTextScale(
    BuildContext context,
    Widget? child, {
    required double presetFactor,
    AppExperiencePreferences preferences = AppExperiencePreferences.defaults,
  }) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final systemReduceMotion = mediaQuery?.disableAnimations ?? false;
    final systemScale = mediaQuery == null
        ? 1.0
        : mediaQuery.textScaler.scale(16) / 16;
    final effectiveScale = (systemScale * presetFactor)
        .clamp(0.90, 1.60)
        .toDouble();
    final scaledChild = mediaQuery == null
        ? child
        : MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(effectiveScale),
            ),
            child: child ?? const SizedBox.shrink(),
          );

    AppFeedbackService.instance.configure(preferences.feedbackPolicy);

    return AppMotionScope(
      policy: preferences.motionPolicy(systemReduceMotion: systemReduceMotion),
      child: ColoredBox(
        color: context.semanticColors.background,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const MedicalAmbientBackground(),
            ScrollConfiguration(
              behavior: const _NanoBioScrollBehavior(),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: FocusTraversalGroup(
                  policy: ReadingOrderTraversalPolicy(),
                  child: scaledChild ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NanoBioScrollBehavior extends MaterialScrollBehavior {
  const _NanoBioScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}
