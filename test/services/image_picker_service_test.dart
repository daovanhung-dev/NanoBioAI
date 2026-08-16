import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nano_app/services/image_picker/image_picker_service.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  late ImagePickerService service;

  setUp(() {
    service = ImagePickerService();
  });

  group('ImagePickerService - validateImage', () {
    test('should return true for valid PNG image under 5MB', () async {
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

  group('ImagePickerService - camera permission', () {
    test('legacy camera call keeps null behavior when permission is denied', () async {
      final deniedService = ImagePickerService(
        cameraPermissionRequest: () async => PermissionStatus.denied,
      );

      expect(await deniedService.pickFromCamera(), isNull);
    });

    test('denied camera permission throws a visible typed error', () async {
      final deniedService = ImagePickerService(
        cameraPermissionRequest: () async => PermissionStatus.denied,
      );

      await expectLater(
        deniedService.pickFromCameraWithPermissionFeedback(),
        throwsA(
          isA<ImagePickerServiceException>()
              .having(
                (error) => error.kind,
                'kind',
                ImagePickerFailureKind.permission,
              )
              .having(
                (error) => error.userMessage,
                'message',
                contains('cho phép NanoBio sử dụng máy ảnh'),
              ),
        ),
      );
    });

    test('permanently denied camera permission guides user to Settings', () async {
      final deniedService = ImagePickerService(
        cameraPermissionRequest: () async => PermissionStatus.permanentlyDenied,
      );

      await expectLater(
        deniedService.pickFromCameraWithPermissionFeedback(),
        throwsA(
          isA<ImagePickerServiceException>()
              .having(
                (error) => error.kind,
                'kind',
                ImagePickerFailureKind.permission,
              )
              .having(
                (error) => error.userMessage,
                'message',
                contains('Cài đặt'),
              ),
        ),
      );
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
      expect(service.pickFromCamera, isA<Function>());
      expect(service.pickFromCameraWithPermissionFeedback, isA<Function>());
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
