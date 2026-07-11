import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

final RegExp _caseIdPattern = RegExp(r'^(PRE|V2|ADM|AUT)-[A-Z0-9-]+$');

class EvidenceCase {
  EvidenceCase({
    required this.caseId,
    required this.surface,
    required this.module,
    required this.personas,
    required this.bdRefs,
    required this.ddRefs,
    required this.routeOrSurface,
    required this.steps,
    required this.expected,
    required this.actual,
  }) {
    if (!_caseIdPattern.hasMatch(caseId)) {
      throw ArgumentError.value(caseId, 'caseId', 'Unknown case ID format');
    }
  }

  final String caseId;
  final String surface;
  final String module;
  final List<String> personas;
  final List<String> bdRefs;
  final List<String> ddRefs;
  final String routeOrSurface;
  final List<String> steps;
  final String expected;
  final String actual;

  Map<String, Object?> toReportData({
    required String screenshotName,
    String? variant,
  }) {
    return <String, Object?>{
      'case_id': caseId,
      'status': 'PASS',
      'surface': surface,
      'module': module,
      'personas': personas,
      'bd_refs': bdRefs,
      'dd_refs': ddRefs,
      'route_or_surface': routeOrSurface,
      'steps': steps,
      'expected': expected,
      'actual': actual,
      'screenshot_name': screenshotName,
      if (variant != null) 'variant': variant,
    };
  }
}

bool _androidSurfaceConverted = false;

Future<void> pumpBootFrames(
  WidgetTester tester, {
  int frameCount = 8,
  Duration frameDuration = const Duration(milliseconds: 250),
}) async {
  for (var index = 0; index < frameCount; index++) {
    await tester.pump(frameDuration);
  }
}

Future<void> capturePassEvidence({
  required IntegrationTestWidgetsFlutterBinding binding,
  required WidgetTester tester,
  required EvidenceCase evidenceCase,
  String? variant,
}) async {
  if (Platform.isAndroid && !_androidSurfaceConverted) {
    await binding.convertFlutterSurfaceToImage();
    _androidSurfaceConverted = true;
  }

  await tester.pump(const Duration(milliseconds: 300));

  final screenshotName = variant == null
      ? '${evidenceCase.caseId}-pass'
      : '${evidenceCase.caseId}-$variant-pass';
  // Android's integration_test callback requires screenshot args to be null.
  // The host driver derives the case ID from the canonical screenshot name.
  final bytes = await binding.takeScreenshot(screenshotName);
  expect(bytes, isNotEmpty);

  binding.reportData ??= <String, dynamic>{};
  final cases =
      binding.reportData!.putIfAbsent('cases', () => <Map<String, Object?>>[])
          as List<dynamic>;
  cases.add(
    evidenceCase.toReportData(screenshotName: screenshotName, variant: variant),
  );
}
