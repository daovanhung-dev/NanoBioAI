import '../entities/ai_content_report.dart';

abstract interface class AiContentReportRepository {
  Future<void> submit(AiContentReport report);
}
