import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nano_app/app/bio_ai_app.dart';
import 'package:nano_app/main.dart' as app;

import '../support/evidence_case.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const caseId = String.fromEnvironment(
    'REGRESSION_CASE_ID',
    defaultValue: 'PRE-02',
  );

  testWidgets('Admin entrypoint boots with sandbox configuration', (
    tester,
  ) async {
    await app.main();
    await pumpBootFrames(tester);

    expect(find.byType(BioAIApp), findsOneWidget);

    await capturePassEvidence(
      binding: binding,
      tester: tester,
      evidenceCase: EvidenceCase(
        caseId: caseId,
        surface: 'admin',
        module: 'PRE',
        personas: const <String>['AS'],
        bdRefs: const <String>['Sandbox gate'],
        ddRefs: const <String>[],
        routeOrSurface: 'lib/main.dart',
        steps: const <String>[
          'Khởi chạy entrypoint Admin bằng cấu hình sandbox đã xác minh.',
          'Chờ các frame bootstrap và xác nhận app root được gắn vào cây widget.',
        ],
        expected: 'Admin boot thành công mà không lộ giá trị cấu hình.',
        actual: 'BioAIApp hợp nhất được render từ entrypoint thật; giao diện sẽ được chọn theo quyền của phiên đăng nhập.',
      ),
      variant: 'admin',
    );
  });
}
