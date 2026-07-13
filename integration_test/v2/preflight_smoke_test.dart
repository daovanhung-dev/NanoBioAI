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

  testWidgets('v2 entrypoint boots with sandbox configuration', (tester) async {
    await app.main();
    await pumpBootFrames(tester);

    expect(find.byType(BioAIApp), findsOneWidget);

    await capturePassEvidence(
      binding: binding,
      tester: tester,
      evidenceCase: EvidenceCase(
        caseId: caseId,
        surface: 'v2',
        module: 'PRE',
        personas: const <String>['G0'],
        bdRefs: const <String>['Sandbox gate'],
        ddRefs: const <String>[],
        routeOrSurface: 'lib/main.dart',
        steps: const <String>[
          'Khởi chạy entrypoint v2 bằng cấu hình sandbox đã xác minh.',
          'Chờ các frame bootstrap và xác nhận app root được gắn vào cây widget.',
        ],
        expected: 'v2 boot thành công mà không lộ giá trị cấu hình.',
        actual: 'BioAIApp hợp nhất được render từ entrypoint thật.',
      ),
    );
  });
}
