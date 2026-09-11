import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_codec;
import 'package:image_picker/image_picker.dart';
import 'package:nano_app/app_versions/v3/features/food_scan/data/services/food_scan_image_service.dart';
import 'package:nano_app/services/image_picker/image_picker_service.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory root;
  late Directory sourceDirectory;
  late FoodScanImageService service;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('nanobio_food_scan_root_');
    sourceDirectory = await Directory.systemTemp.createTemp(
      'nanobio_food_scan_source_',
    );
    service = FoodScanImageService(
      pickerService: ImagePickerService(),
      rootDirectory: () async => root,
      now: () => DateTime.utc(2026, 8, 31, 1, 2, 3),
    );
  });

  tearDown(() async {
    await root.delete(recursive: true);
    await sourceDirectory.delete(recursive: true);
  });

  test(
    'prepares a local JPEG within the Edge Function payload budget',
    () async {
      final source = File(path.join(sourceDirectory.path, 'meal.png'));
      final rawImage = image_codec.Image(width: 2400, height: 1200);
      image_codec.fill(rawImage, color: image_codec.ColorRgb8(20, 160, 120));
      await source.writeAsBytes(image_codec.encodePng(rawImage));

      final prepared = await service.prepare(
        XFile(source.path),
        userId: 'user/1',
      );
      final saved = File(prepared.path);
      final decoded = image_codec.decodeJpg(await saved.readAsBytes());

      expect(prepared.mimeType, 'image/jpeg');
      expect(
        prepared.path,
        contains('food_scans${Platform.pathSeparator}user_1'),
      );
      expect(decoded, isNotNull);
      expect(decoded!.width, 1536);
      expect(decoded.height, 768);
      expect(decoded.exif.isEmpty, isTrue);
      expect(
        await saved.length(),
        lessThanOrEqualTo(FoodScanImageService.maxEncodedBytes),
      );
    },
  );
}
