import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'medical_ui.dart';

/// App-level UX wrapper shared by V1, V2, V3, Admin and Sale surfaces.
///
/// It gives every route a consistent medical ambient canvas, keeps keyboard
/// traversal predictable and enables mouse-drag scrolling on desktop.
class AppExperience {
  const AppExperience._();

  static Widget builder(BuildContext context, Widget? child) {
    return builderWithTextScale(context, child, presetFactor: 1);
  }

  static Widget builderWithTextScale(
    BuildContext context,
    Widget? child, {
    required double presetFactor,
  }) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final reduceMotion = mediaQuery?.disableAnimations ?? false;
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

    return ColoredBox(
      color: AppColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const MedicalAmbientBackground(),
          ScrollConfiguration(
            behavior: const _NanoBioScrollBehavior(),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: TickerMode(
                enabled: !reduceMotion,
                child: FocusTraversalGroup(
                  policy: ReadingOrderTraversalPolicy(),
                  child: scaledChild ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
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
