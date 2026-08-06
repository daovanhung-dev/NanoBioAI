import 'package:flutter/services.dart';

import 'app_feedback_type.dart';

abstract interface class AppHapticAdapter {
  Future<void> emit(AppHapticPattern pattern);
}

class SystemAppHapticAdapter implements AppHapticAdapter {
  const SystemAppHapticAdapter();

  @override
  Future<void> emit(AppHapticPattern pattern) async {
    switch (pattern) {
      case AppHapticPattern.none:
        return;
      case AppHapticPattern.selection:
        await HapticFeedback.selectionClick();
        return;
      case AppHapticPattern.light:
        await HapticFeedback.lightImpact();
        return;
      case AppHapticPattern.medium:
        await HapticFeedback.mediumImpact();
        return;
      case AppHapticPattern.heavy:
        await HapticFeedback.heavyImpact();
        return;
    }
  }
}
