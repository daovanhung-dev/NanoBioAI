import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/ai_content_report.dart';

abstract interface class AiContentReportRemoteDatasource {
  Future<void> submit(AiContentReport report);
}

class SupabaseAiContentReportRemoteDatasource
    implements AiContentReportRemoteDatasource {
  final SupabaseClient? clientOverride;

  const SupabaseAiContentReportRemoteDatasource({this.clientOverride});

  @override
  Future<void> submit(AiContentReport report) async {
    final client = clientOverride ?? Supabase.instance.client;
    final response = await client.functions.invoke(
      'report-ai-content',
      body: report.toMap(),
    );
    final data = response.data;
    if (data is Map && data['accepted'] == true) return;
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
