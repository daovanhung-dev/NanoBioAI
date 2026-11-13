import 'package:flutter/material.dart';

import 'package:nano_app/app_versions/v1/router/v1_navigation_service.dart';

import '../widgets/result_step.dart';

@immutable
class OnboardingResultRouteData {
  const OnboardingResultRouteData({required this.message});

  final String message;
}

class OnboardingResultPage extends StatelessWidget {
  const OnboardingResultPage({super.key, required this.message});

  final String message;

  void _goToMenu(BuildContext context) => V1AppNavigator.goMenu(context);

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goToMenu(context);
      },
      child: ResultStep(message: message, onContinue: () => _goToMenu(context)),
    );
  }
}
