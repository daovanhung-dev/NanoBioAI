import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_codec;
import 'package:image_picker/image_picker.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/application/schedule_proof_image_service.dart';
import 'package:nano_app/services/image_picker/image_picker_service.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory root;
  late Directory sourceDirectory;
  late ScheduleProofImageService service;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('nanobio_proof_root_');
    sourceDirectory = await Directory.systemTemp.createTemp(
      'nanobio_proof_source_',
    );
    service = ScheduleProofImageService(
      imagePickerService: ImagePickerService(),
      rootDirectory: () async => root,
      now: () => DateTime.utc(2026, 7, 13, 1, 2, 3),
    );
  });

  tearDown(() async {
    await root.delete(recursive: true);
    await sourceDirectory.delete(recursive: true);
  });

  test('normalizes proof to private relative JPEG path', () async {
    final source = File(path.join(sourceDirectory.path, 'camera.png'));
    final rawImage = image_codec.Image(width: 2400, height: 1200);
    image_codec.fill(rawImage, color: image_codec.ColorRgb8(20, 160, 120));
    await source.writeAsBytes(image_codec.encodePng(rawImage));

    final storedPath = await service.normalizeAndSaveProof(
      XFile(source.path),
      itemId: 'task/unsafe',
    );
    final saved = await service.resolveProofFile(storedPath);
    final decoded = image_codec.decodeJpg(await saved.readAsBytes());

    expect(storedPath, startsWith('schedule_proofs/'));
    expect(storedPath, endsWith('.jpg'));
    expect(storedPath, isNot(contains('..')));
    expect(await saved.exists(), isTrue);
    expect(decoded, isNotNull);
    expect(decoded!.width, 1920);
    expect(decoded.height, 960);
    expect(decoded.exif.isEmpty, isTrue);
    expect(await saved.length(), lessThanOrEqualTo(5 * 1024 * 1024));
  });

  test('deleteProof only deletes app-relative proof', () async {
    final relative = 'schedule_proofs/delete-me.jpg';
    final file = await service.resolveProofFile(relative);
    await file.parent.create(recursive: true);
    await file.writeAsString('proof');

    await service.deleteProof(relative);

    expect(await file.exists(), isFalse);
  });
}
