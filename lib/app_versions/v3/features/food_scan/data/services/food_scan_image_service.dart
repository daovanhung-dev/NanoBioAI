import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:nano_app/services/image_picker/image_picker_service.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../domain/food_scan_exception.dart';

class PreparedFoodScanImage {
  final String path;
  final String mimeType;

  const PreparedFoodScanImage({required this.path, this.mimeType = 'image/jpeg'});
}

class FoodScanImageService {
  /// Keep the base64 request below the Edge Function's image and body limits.
  /// The remaining budget is reserved for the prompt and JSON envelope.
  static const maxEncodedBytes = 900000;
  static const _initialJpegQuality = 84;
  static const _minimumJpegQuality = 50;
  static const _minimumDimension = 640;

  final ImagePickerService pickerService;
  final Future<Directory> Function() _rootDirectory;
  final DateTime Function() _now;

  FoodScanImageService({
    ImagePickerService? pickerService,
    Future<Directory> Function()? rootDirectory,
    DateTime Function()? now,
  }) : pickerService = pickerService ?? ImagePickerService(),
       _rootDirectory = rootDirectory ?? getApplicationDocumentsDirectory,
       _now = now ?? DateTime.now;

  Future<PreparedFoodScanImage?> pickCamera({required String userId}) async {
    try {
      final picked = await pickerService.pickFromCameraWithPermissionFeedback();
      if (picked == null) return null;
      return await prepare(picked, userId: userId);
    } on ImagePickerServiceException catch (error) {
      throw FoodScanException(
        code: 'CAMERA_PICK_FAILED',
        userMessage: error.userMessage,
        cause: error,
      );
    }
  }

  Future<PreparedFoodScanImage?> pickGallery({required String userId}) async {
    try {
      final picked = await pickerService.pickFromGallery();
      if (picked == null) return null;
      return await prepare(picked, userId: userId);
    } on ImagePickerServiceException catch (error) {
      throw FoodScanException(
        code: 'GALLERY_PICK_FAILED',
        userMessage: error.userMessage,
        cause: error,
      );
    }
  }

  Future<PreparedFoodScanImage> prepare(
    XFile source, {
    required String userId,
  }) async {
    final validationError = await pickerService.getValidationError(source);
    if (validationError != null) {
      throw FoodScanException(
        code: 'INVALID_IMAGE',
        userMessage: validationError,
      );
    }

    try {
      final bytes = await source.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw const FoodScanException(
          code: 'IMAGE_DECODE_FAILED',
          userMessage: 'Nabi chưa đọc được ảnh này. Bạn thử chọn ảnh khác nhé.',
        );
      }

      var normalized = img.bakeOrientation(decoded);
      const maxDimension = 1536;
      if (normalized.width > maxDimension || normalized.height > maxDimension) {
        normalized = normalized.width >= normalized.height
            ? img.copyResize(normalized, width: maxDimension)
            : img.copyResize(normalized, height: maxDimension);
      }

      // Do not carry source metadata into the local copy or the AI request.
      normalized.exif.clear();
      final encoded = _encodeWithinRequestLimit(normalized);
      final appDir = await _rootDirectory();
      final safeUser = _safeSegment(userId);
      final targetDir = Directory(
        path.join(appDir.path, 'food_scans', safeUser),
      );
      await targetDir.create(recursive: true);
      final filename =
          'food_scan_${_now().toUtc().microsecondsSinceEpoch}.jpg';
      final target = File(path.join(targetDir.path, filename));
      await target.writeAsBytes(encoded, flush: true);
      return PreparedFoodScanImage(path: target.path);
    } on FoodScanException {
      rethrow;
    } catch (error) {
      throw FoodScanException(
        code: 'IMAGE_PROCESS_FAILED',
        userMessage:
            'Nabi chưa thể chuẩn bị ảnh này để phân tích. Bạn thử lại với ảnh khác nhé.',
        cause: error,
      );
    }
  }

  Future<void> deleteLocalImage(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  String _safeSegment(String value) {
    final safe = value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return safe.isEmpty ? 'user' : safe;
  }

  List<int> _encodeWithinRequestLimit(img.Image source) {
    var candidate = source;
    var quality = _initialJpegQuality;
    var encoded = img.encodeJpg(candidate, quality: quality);

    while (encoded.length > maxEncodedBytes) {
      if (quality > _minimumJpegQuality) {
        quality = math.max(_minimumJpegQuality, quality - 8);
      } else {
        final currentDimension = math.max(candidate.width, candidate.height);
        if (currentDimension <= _minimumDimension) break;

        final nextDimension = math.max(
          _minimumDimension,
          (currentDimension * 0.8).round(),
        );
        candidate = candidate.width >= candidate.height
            ? img.copyResize(candidate, width: nextDimension)
            : img.copyResize(candidate, height: nextDimension);
        candidate.exif.clear();
        quality = 72;
      }
      encoded = img.encodeJpg(candidate, quality: quality);
    }

    if (encoded.length > maxEncodedBytes) {
      throw const FoodScanException(
        code: 'IMAGE_TOO_LARGE',
        userMessage:
            'Ảnh món ăn vẫn quá lớn sau khi tối ưu. Bạn thử chụp gần hơn hoặc chọn ảnh khác nhé.',
      );
    }
    return encoded;
  }
}
