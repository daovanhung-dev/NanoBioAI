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
    return ColoredBox(
      color: AppColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const MedicalAmbientBackground(),
          ScrollConfiguration(
            behavior: const _NanoBioScrollBehavior(),
            child: FocusTraversalGroup(
              policy: ReadingOrderTraversalPolicy(),
              child: child ?? const SizedBox.shrink(),
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
