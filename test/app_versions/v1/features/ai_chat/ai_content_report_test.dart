import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/data/datasources/ai_content_report_remote_datasource.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/data/repositories/ai_content_report_repository_impl.dart';
import 'package:nano_app/app_versions/v1/features/ai_chat/domain/entities/ai_content_report.dart';

void main() {
  test('uses assistant-only bounded report payload', () async {
    final datasource = _FakeReportDatasource();
    final repository = AiContentReportRepositoryImpl(datasource: datasource);
    final longText = 'x' * (AiContentReport.maxSnapshotLength + 100);

    await repository.submit(
      AiContentReport(
        messageId: 'assistant-1',
        reason: AiContentReportReason.unsafe,
        note: 'x' * (AiContentReport.maxNoteLength + 100),
        messageSnapshot: longText,
        appVersion: '1.0.0+1',
      ),
    );

    expect(datasource.lastPayload?['message_role'], 'assistant');
    expect(datasource.lastPayload?['reason_code'], 'unsafe');
    expect(
      (datasource.lastPayload?['message_snapshot'] as String).length,
      AiContentReport.maxSnapshotLength,
    );
    expect(
      (datasource.lastPayload?['note'] as String).length,
      AiContentReport.maxNoteLength,
    );
  });

  test('fails closed when the reported answer has no stable content', () async {
    final repository = AiContentReportRepositoryImpl(
      datasource: _FakeReportDatasource(),
    );

    expect(
      () => repository.submit(
        const AiContentReport(
          messageId: 'assistant-1',
          reason: AiContentReportReason.other,
          messageSnapshot: ' ',
          appVersion: '1.0.0',
        ),
      ),
      throwsA(isA<AiContentReportException>()),
    );
  });
}

class _FakeReportDatasource implements AiContentReportRemoteDatasource {
  Map<String, Object?>? lastPayload;

  @override
  Future<void> submit(AiContentReport report) async {
    lastPayload = report.toMap();
  }
}
