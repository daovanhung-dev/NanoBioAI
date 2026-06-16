import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef OnboardingCompletionCallback = Future<void> Function();

final onboardingCompletionCallbackProvider =
    Provider<OnboardingCompletionCallback>((ref) {
      return () async {};
    });
