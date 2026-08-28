import '../../domain/entities/ai_content_report.dart';
import '../../domain/repositories/ai_content_report_repository.dart';
import '../datasources/ai_content_report_remote_datasource.dart';

class AiContentReportRepositoryImpl implements AiContentReportRepository {
  final AiContentReportRemoteDatasource datasource;

  const AiContentReportRepositoryImpl({required this.datasource});

  @override
  Future<void> submit(AiContentReport report) {
    if (report.messageId.trim().isEmpty ||
        report.messageSnapshot.trim().isEmpty) {
      throw const AiContentReportException(
        'INVALID_REPORT',
        'Phản hồi cần có nội dung để Nabi kiểm tra.',
      );
    }
    return datasource.submit(report);
  }
}
