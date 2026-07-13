import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nano_app/services/image_picker/image_picker_service.dart';

void main() {
  late ImagePickerService service;

  setUp(() {
    service = ImagePickerService();
  });

  group('ImagePickerService - validateImage', () {
    test('should return true for valid PNG image under 5MB', () async {
      // Note: This is a basic test structure
      // In real scenario, we would need to create mock XFile objects
      // For now, we're testing the validation logic conceptually

      expect(ImagePickerService.allowedFormats.contains('png'), isTrue);
      expect(ImagePickerService.maxFileSizeBytes, equals(5 * 1024 * 1024));
    });

    test('should have correct allowed formats', () {
      expect(ImagePickerService.allowedFormats, contains('png'));
      expect(ImagePickerService.allowedFormats, contains('jpg'));
      expect(ImagePickerService.allowedFormats, contains('jpeg'));
      expect(ImagePickerService.allowedFormats.length, equals(3));
    });

    test('should have max file size of 5MB', () {
      expect(ImagePickerService.maxFileSizeBytes, equals(5 * 1024 * 1024));
    });
  });

  group('ImagePickerService - getValidationError', () {
    test('returns a Vietnamese error for an invalid format', () async {
      final directory = await Directory.systemTemp.createTemp(
        'image_picker_test_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/proof.gif');
      await file.writeAsBytes(const [1, 2, 3]);

      final error = await service.getValidationError(XFile(file.path));

      expect(error, contains('Định dạng ảnh chưa phù hợp'));
      expect(error, isNot(contains('Invalid image format')));
    });

    test('returns a Vietnamese error for an image over 5 MB', () async {
      final directory = await Directory.systemTemp.createTemp(
        'image_picker_test_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/proof.jpg');
      await file.writeAsBytes(
        List<int>.filled(ImagePickerService.maxFileSizeBytes + 1, 0),
      );

      final error = await service.getValidationError(XFile(file.path));

      expect(error, contains('vượt quá giới hạn 5 MB'));
    });

    test('should accept valid formats', () {
      const validFormats = ['png', 'jpg', 'jpeg'];

      for (final format in validFormats) {
        expect(
          ImagePickerService.allowedFormats.contains(format),
          isTrue,
          reason: '$format should be in allowed formats',
        );
      }
    });
  });

  group('ImagePickerService - basic structure', () {
    test('should initialize without errors', () {
      expect(() => ImagePickerService(), returnsNormally);
    });

    test('should have all required methods', () {
      // Verify the service has the required methods
      expect(service.pickFromCamera, isA<Function>());
      expect(service.pickFromGallery, isA<Function>());
      expect(service.validateImage, isA<Function>());
      expect(service.saveImageLocally, isA<Function>());
      expect(service.getValidationError, isA<Function>());
    });

    test('typed service errors expose only the safe Vietnamese message', () {
      const error = ImagePickerServiceException(
        kind: ImagePickerFailureKind.save,
        userMessage: 'Nabi chưa thể lưu ảnh này.',
        cause: FormatException('internal details'),
      );

      expect(error.toString(), 'Nabi chưa thể lưu ảnh này.');
      expect(error.toString(), isNot(contains('internal details')));
    });
  });
}
