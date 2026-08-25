import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';

import '../domain/entities/sleep_safety_session.dart';
import 'sleep_night_analysis_controller.dart';
import 'sleep_safety_providers.dart';

final sleepNightAnalysisControllerProvider =
    NotifierProvider<SleepNightAnalysisController, SleepNightAnalysisViewState>(
  SleepNightAnalysisController.new,
);

final recentSleepSessionsProvider = FutureProvider<List<SleepSafetySession>>((ref) async {
  final userId = ref.watch(currentAuthUserIdProvider);
  if (userId == null) return const <SleepSafetySession>[];
  return ref.watch(sleepSafetyRepositoryProvider).listSessions(userId, limit: 20);
});
