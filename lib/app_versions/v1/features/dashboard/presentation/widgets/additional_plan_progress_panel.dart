import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:nano_app/shared/widgets/generated_plan_progress_panel.dart';

class AdditionalPlanProgressPanel extends ConsumerWidget {
  const AdditionalPlanProgressPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(additionalPlanProgressProvider);
    return GeneratedPlanProgressPanel(progress: progress);
  }
}
