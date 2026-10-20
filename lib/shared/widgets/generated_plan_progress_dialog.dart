import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/presentation/widgets/additional_plan_progress_panel.dart';
import 'package:nano_app/shared/widgets/loading_gen_ai.dart';

VoidCallback showGeneratedPlanProgressDialog(BuildContext context) {
  final navigator = Navigator.of(context, rootNavigator: true);
  var closed = false;
  unawaited(
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Đang tạo lịch trình',
      barrierColor: Colors.black54,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) => const PopScope(
        canPop: false,
        child: AIGeneratingPage(progressContent: AdditionalPlanProgressPanel()),
      ),
    ),
  );
  return () {
    if (closed) return;
    closed = true;
    if (navigator.mounted && navigator.canPop()) navigator.pop();
  };
}
