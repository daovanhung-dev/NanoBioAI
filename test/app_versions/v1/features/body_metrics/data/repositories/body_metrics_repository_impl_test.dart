import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/data/datasources/body_metrics_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/data/repositories/body_metrics_repository_impl.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/entities/body_metrics_health_snapshot.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/entities/body_metrics_personal_context.dart';

class _CapturingDatasource extends BodyMetricsLocalDatasource {
  String? receivedSubjectId;

  _CapturingDatasource() : super(databaseLoader: _unsupportedDatabase);

  @override
  Future<BodyMetricsHealthSnapshot?> loadHealthSnapshot({String? userId}) async {
    receivedSubjectId = userId;
    return null;
  }

  @override
  Future<BodyMetricsPersonalContext?> loadPersonalContext({String? userId}) async {
    receivedSubjectId = userId;
    return null;
  }
}

Future<Never> _unsupportedDatabase() async => throw UnsupportedError('not used');

void main() {
  test('repository always forwards the explicitly resolved current subject', () async {
    final datasource = _CapturingDatasource();
    final repository = BodyMetricsRepositoryImpl(
      datasource: datasource,
      resolveSubjectId: () async => 'current-subject',
    );

    await repository.loadHealthSnapshot();
    expect(datasource.receivedSubjectId, 'current-subject');

    await repository.loadPersonalContext();
    expect(datasource.receivedSubjectId, 'current-subject');
  });
}
