import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/access/local_subject_resolver.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/services/access/product_access_level.dart';
import 'package:nano_app/services/access/product_access_reader.dart';
import 'package:nano_app/services/access/trusted_product_access_reader.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

import '../application/body_metrics_ai_service.dart';
import '../application/body_metrics_analysis_orchestrator.dart';
import '../data/datasources/body_metrics_local_datasource.dart';
import '../data/repositories/body_metrics_repository_impl.dart';
import '../domain/entities/body_metrics_ai_models.dart';
import '../domain/entities/body_metrics_health_report.dart';
import '../domain/entities/body_metrics_health_snapshot.dart';
import '../domain/entities/body_metrics_personal_context.dart';
import '../domain/repositories/body_metrics_repository.dart';
import '../domain/services/body_metrics_formula_engine.dart';

final bodyMetricsLocalDatasourceProvider = Provider<BodyMetricsLocalDatasource>(
  (ref) => BodyMetricsLocalDatasource(),
);

final bodyMetricsSubjectResolverProvider = Provider<LocalSubjectResolver>((ref) {
  return LocalSubjectResolver(
    currentActorId: currentSupabaseUserIdOrNull,
    pendingGuestUserId: AppPrefs.pendingGuestUserId,
  );
});

final bodyMetricsRepositoryProvider = Provider<BodyMetricsRepository>((ref) {
  final resolver = ref.read(bodyMetricsSubjectResolverProvider);
  return BodyMetricsRepositoryImpl(
    datasource: ref.read(bodyMetricsLocalDatasourceProvider),
    resolveSubjectId: resolver.resolve,
  );
});

final bodyMetricsPersonalContextProvider =
    FutureProvider<BodyMetricsPersonalContext?>((ref) {
  return ref.watch(bodyMetricsRepositoryProvider).loadPersonalContext();
});

final bodyMetricsAiServiceProvider = Provider<BodyMetricsAiService>(
  (ref) => const BodyMetricsAiService(),
);

final bodyMetricsProductAccessReaderProvider = Provider<ProductAccessReader>(
  (ref) => const TrustedProductAccessReader(),
);

final bodyMetricsAnalysisOrchestratorProvider = Provider<BodyMetricsAnalysisOrchestrator>((ref) {
  return BodyMetricsAnalysisOrchestrator(
    aiService: ref.read(bodyMetricsAiServiceProvider),
    accessReader: ref.read(bodyMetricsProductAccessReaderProvider),
  );
});

enum BodyMetricsStatus { loadingData, ready, calculating, analyzing, partial, success, error }

class BodyMetricsState {
  final BodyMetricsStatus status;
  final BodyMetricsHealthSnapshot? snapshot;
  final BodyMetricsHealthReport? report;
  final BodyMetricsAiBundle? aiBundle;
  final int currentAiStage;
  final int totalAiStages;
  final String? currentStageId;
  final String? error;

  const BodyMetricsState({
    required this.status,
    this.snapshot,
    this.report,
    this.aiBundle,
    this.currentAiStage = 0,
    this.totalAiStages = 0,
    this.currentStageId,
    this.error,
  });

  const BodyMetricsState.initial() : this(status: BodyMetricsStatus.loadingData);

  BodyMetricsState copyWith({
    BodyMetricsStatus? status,
    BodyMetricsHealthSnapshot? snapshot,
    BodyMetricsHealthReport? report,
    BodyMetricsAiBundle? aiBundle,
    int? currentAiStage,
    int? totalAiStages,
    String? currentStageId,
    String? error,
    bool clearError = false,
  }) {
    return BodyMetricsState(
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
      report: report ?? this.report,
      aiBundle: aiBundle ?? this.aiBundle,
      currentAiStage: currentAiStage ?? this.currentAiStage,
      totalAiStages: totalAiStages ?? this.totalAiStages,
      currentStageId: currentStageId ?? this.currentStageId,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class BodyMetricsController extends Notifier<BodyMetricsState> {
  @override
  BodyMetricsState build() => const BodyMetricsState.initial();

  Future<void> load() async {
    state = const BodyMetricsState.initial();
    try {
      final snapshot = await ref.read(bodyMetricsRepositoryProvider).loadHealthSnapshot();
      if (snapshot == null) {
        state = const BodyMetricsState(
          status: BodyMetricsStatus.error,
          error: 'Nabi chưa xác định được hồ sơ sức khỏe đang sử dụng.',
        );
        return;
      }
      state = BodyMetricsState(
        status: BodyMetricsStatus.calculating,
        snapshot: snapshot,
      );
      final report = BodyMetricsFormulaEngine.calculate(snapshot);
      final access = await ref.read(bodyMetricsProductAccessReaderProvider).read();
      state = BodyMetricsState(
        status: BodyMetricsStatus.ready,
        snapshot: snapshot,
        report: report,
        totalAiStages: access.bodyMetricsAiStages,
      );
    } catch (_) {
      state = const BodyMetricsState(
        status: BodyMetricsStatus.error,
        error: 'Nabi chưa thể đọc dữ liệu sức khỏe lúc này.',
      );
    }
  }

  Future<void> analyze() async {
    final snapshot = state.snapshot;
    final report = state.report;
    if (snapshot == null || report == null || state.status == BodyMetricsStatus.analyzing) return;
    state = state.copyWith(
      status: BodyMetricsStatus.analyzing,
      currentAiStage: 0,
      totalAiStages: state.totalAiStages > 0 ? state.totalAiStages : 5,
      currentStageId: 'P01',
      clearError: true,
    );
    try {
      final bundle = await ref.read(bodyMetricsAnalysisOrchestratorProvider).analyze(
        snapshot: snapshot,
        report: report,
        onProgress: (completed, total, stageId) {
          state = state.copyWith(
            status: BodyMetricsStatus.analyzing,
            currentAiStage: completed,
            totalAiStages: total,
            currentStageId: stageId,
          );
        },
      );
      state = state.copyWith(
        status: bundle.isPartial ? BodyMetricsStatus.partial : BodyMetricsStatus.success,
        aiBundle: bundle,
        currentAiStage: bundle.completedStages,
        totalAiStages: bundle.totalStages,
      );
    } catch (_) {
      state = state.copyWith(
        status: BodyMetricsStatus.partial,
        error: 'Phân tích AI tạm thời chưa hoàn tất. Các chỉ số đã tính vẫn được giữ nguyên.',
      );
    }
  }
}

final bodyMetricsControllerProvider =
    NotifierProvider<BodyMetricsController, BodyMetricsState>(BodyMetricsController.new);
