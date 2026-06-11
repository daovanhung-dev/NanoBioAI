import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/controllers/onboarding_controller.dart';

final onboardingProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );
