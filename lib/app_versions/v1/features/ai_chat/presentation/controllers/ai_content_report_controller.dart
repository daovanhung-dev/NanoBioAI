import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/ai_content_report_remote_datasource.dart';
import '../../data/repositories/ai_content_report_repository_impl.dart';
import '../../domain/entities/ai_content_report.dart';
import '../../domain/repositories/ai_content_report_repository.dart';

enum AiContentReportStatus { idle, submitting, success, error }

class AiContentReportState {
  final AiContentReportStatus status;
  final String? message;
  final bool retryable;

  const AiContentReportState({
    this.status = AiContentReportStatus.idle,
    this.message,
    this.retryable = false,
  });
}

final aiContentReportRemoteDatasourceProvider =
    Provider<AiContentReportRemoteDatasource>((ref) {
      return const SupabaseAiContentReportRemoteDatasource();
    });

final aiContentReportRepositoryProvider = Provider<AiContentReportRepository>((
  ref,
) {
  return AiContentReportRepositoryImpl(
    datasource: ref.watch(aiContentReportRemoteDatasourceProvider),
  );
});

final aiContentReportControllerProvider =
    NotifierProvider<AiContentReportController, AiContentReportState>(
      AiContentReportController.new,
    );

class AiContentReportController extends Notifier<AiContentReportState> {
  AiContentReportRepository get _repository =>
      ref.read(aiContentReportRepositoryProvider);

  @override
  AiContentReportState build() => const AiContentReportState();

  Future<bool> submit({
    required String messageId,
    required String messageSnapshot,
    required AiContentReportReason reason,
    String? note,
  }) async {
    if (state.status == AiContentReportStatus.submitting) return false;
    state = const AiContentReportState(
      status: AiContentReportStatus.submitting,
    );
    try {
      await _repository.submit(
        AiContentReport(
          messageId: messageId,
          reason: reason,
          note: note,
          messageSnapshot: messageSnapshot,
          appVersion: const String.fromEnvironment(
            'APP_VERSION',
            defaultValue: 'unknown',
          ),
        ),
      );
      state = const AiContentReportState(status: AiContentReportStatus.success);
      return true;
    } on AiContentReportException catch (error) {
      state = AiContentReportState(
        status: AiContentReportStatus.error,
        message: error.safeMessage,
        retryable: error.retryable,
      );
      return false;
    } catch (_) {
      state = const AiContentReportState(
        status: AiContentReportStatus.error,
        message: 'Chưa gửi được báo cáo. Bạn hãy thử lại sau.',
        retryable: true,
      );
      return false;
    }
  }

  void reset() => state = const AiContentReportState();
}
