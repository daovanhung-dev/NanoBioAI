import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';
import 'package:path/path.dart' as path;

final RegExp _caseIdPattern = RegExp(r'^(PRE|V2|ADM|AUT)-[A-Z0-9-]+$');
final RegExp _commandIdPattern = RegExp(r'^[A-Za-z0-9._-]+$');
final RegExp _screenshotNamePattern = RegExp(
  r'^((?:PRE-[0-9]+|V2-M[0-9]{2}-[0-9]+|ADM-M[0-9]{2}[A-Z]?-[0-9]+|AUT-M[0-9]{2}-[0-9]+))(?:-([a-z0-9]+(?:-[a-z0-9]+)*))?-(pass|fail-before-fix)$',
);

Future<void> main() async {
  final repoRoot = path.normalize(Directory.current.absolute.path);
  final requestedRoot = Platform.environment['NANOBIO_EVIDENCE_ROOT'];
  final testDocsRoot = path.normalize(path.join(repoRoot, 'docs', 'test'));
  final evidenceRoot = path.normalize(
    path.absolute(
      requestedRoot ?? path.join(testDocsRoot, 'v2-admin-regression'),
    ),
  );
  if (!path.isWithin(testDocsRoot, evidenceRoot)) {
    throw StateError('Evidence output must stay inside docs/test.');
  }

  final commandId = Platform.environment['NANOBIO_TEST_COMMAND_ID'];
  if (commandId == null || !_commandIdPattern.hasMatch(commandId)) {
    throw StateError('NANOBIO_TEST_COMMAND_ID is missing or invalid.');
  }

  final assetsDirectory = Directory(path.join(evidenceRoot, 'assets'));
  final runsDirectory = Directory(path.join(evidenceRoot, 'evidence', 'runs'));
  await assetsDirectory.create(recursive: true);
  await runsDirectory.create(recursive: true);

  await integrationDriver(
    writeResponseOnFailure: true,
    onScreenshot: (name, image, [args]) async {
      final nameMatch = _screenshotNamePattern.firstMatch(name);
      final caseId = nameMatch?.group(1);
      if (caseId == null || !_caseIdPattern.hasMatch(caseId)) {
        throw StateError('Screenshot name is not canonical.');
      }

      final target = File(path.join(assetsDirectory.path, '$name.png'));
      if (!path.isWithin(assetsDirectory.path, target.absolute.path)) {
        throw StateError('Refusing to write screenshot outside assets.');
      }
      final allowOverwrite =
          Platform.environment['NANOBIO_EVIDENCE_ALLOW_OVERWRITE'] == 'YES';
      if (await target.exists() && !allowOverwrite) {
        throw StateError(
          'Evidence already exists. Set explicit overwrite confirmation.',
        );
      }
      await target.writeAsBytes(image, flush: true);
      return true;
    },
    responseDataCallback: (data) async {
      final screenshotNames = <String>[];
      final screenshots = data?['screenshots'];
      if (screenshots is List<dynamic>) {
        for (final item in screenshots) {
          if (item is Map<dynamic, dynamic> &&
              item['screenshotName'] is String) {
            screenshotNames.add(item['screenshotName'] as String);
          }
        }
      }

      final safeRunData = <String, Object?>{
        'command_id': commandId,
        'recorded_at': DateTime.now().toUtc().toIso8601String(),
        'cases': data?['cases'] ?? <Object?>[],
        'screenshots': screenshotNames,
      };
      final target = File(
        path.join(runsDirectory.path, '$commandId-driver.json'),
      );
      if (!path.isWithin(evidenceRoot, target.absolute.path)) {
        throw StateError('Refusing to write run data outside evidence root.');
      }
      await target.writeAsString(
        const JsonEncoder.withIndent('  ').convert(safeRunData),
        flush: true,
      );
    },
  );
}
