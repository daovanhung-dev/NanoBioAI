import 'package:nano_app/core/network/backend_api_client.dart';

import '../../domain/entities/ai_content_report.dart';

abstract interface class AiContentReportRemoteDatasource {
  Future<void> submit(AiContentReport report);
}

class BackendAiContentReportRemoteDatasource
    implements AiContentReportRemoteDatasource {
  final BackendApiClient? clientOverride;

  const BackendAiContentReportRemoteDatasource({this.clientOverride});

  @override
  Future<void> submit(AiContentReport report) async {
    final client = clientOverride ?? BackendApiClient.shared;
    try {
      final data = await client.requestMap(
        'POST',
        '/api/v1/ai-content-reports',
        authenticated: false,
        body: report.toMap(),
      );
      if (data['received'] == true) return;
    } on BackendApiException catch (error) {
      throw AiContentReportException(
        error.businessCode,
        error.message,
        retryable: error.statusCode == 0 || error.statusCode >= 500,
      );
    }
    throw const AiContentReportException(
      'REPORT_NOT_ACCEPTED',
      'Chưa gửi được báo cáo. Bạn hãy thử lại sau.',
      retryable: true,
    );
  }
}

class AiContentReportException implements Exception {
  final String code;
  final String safeMessage;
  final bool retryable;

  const AiContentReportException(
    this.code,
    this.safeMessage, {
    this.retryable = false,
  });

  @override
  String toString() => '$code: $safeMessage';
}
