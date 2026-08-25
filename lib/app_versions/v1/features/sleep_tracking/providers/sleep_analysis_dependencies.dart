import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/sleep_analysis_ai_service.dart';
import '../domain/services/sleep_night_analysis_service.dart';

final sleepNightAnalysisServiceProvider = Provider<SleepNightAnalysisService>(
  (ref) => const SleepNightAnalysisService(),
);

final sleepAnalysisAIServiceProvider = Provider<SleepAnalysisAIService>(
  (ref) => SleepAnalysisAIService(),
);
