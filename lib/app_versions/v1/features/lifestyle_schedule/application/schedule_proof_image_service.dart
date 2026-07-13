import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as image_codec;
import 'package:image_picker/image_picker.dart';
import 'package:nano_app/services/image_picker/image_picker_service.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

enum ScheduleProofErrorCode { invalidImage, imageTooLarge, cannotSave }

class ScheduleProofException implements Exception {
  final ScheduleProofErrorCode code;
  final String message;

  const ScheduleProofException(this.code, this.message);

  @override
  String toString() => message;
}

class ScheduleProofImageService {
  static const proofDirectoryName = 'schedule_proofs';
  static const _maxDimension = 1920;

  final ImagePickerService imagePickerService;
  final Future<Directory> Function() _rootDirectory;
  final DateTime Function() _now;

  ScheduleProofImageService({
    required this.imagePickerService,
    Future<Directory> Function()? rootDirectory,
    DateTime Function()? now,
  }) : _rootDirectory = rootDirectory ?? getApplicationDocumentsDirectory,
       _now = now ?? DateTime.now;

  Future<String?> captureProofForItem(String itemId) async {
    final image = await imagePickerService.pickFromCamera();
    if (image == null) return null;

    final validationError = await imagePickerService.getValidationError(image);
    if (validationError != null) {
      throw ScheduleProofException(
        ScheduleProofErrorCode.invalidImage,
        validationError,
      );
    }
    return normalizeAndSaveProof(image, itemId: itemId);
  }

  /// Giải mã và mã hóa lại JPEG để áp dụng hướng xoay, giới hạn kích thước và
  /// loại metadata (bao gồm vị trí) trước khi ảnh được lưu hoặc tải lên cloud.
  Future<String> normalizeAndSaveProof(
    XFile source, {
    required String itemId,
  }) async {
    try {
      final decoded = image_codec.decodeImage(await source.readAsBytes());
      if (decoded == null) {
        throw const ScheduleProofException(
          ScheduleProofErrorCode.invalidImage,
          'Ảnh minh chứng không hợp lệ. Bạn chụp lại ảnh khác nhé.',
        );
      }

      var normalized = image_codec.bakeOrientation(decoded);
      if (normalized.width > _maxDimension ||
          normalized.height > _maxDimension) {
        normalized = normalized.width >= normalized.height
            ? image_codec.copyResize(normalized, width: _maxDimension)
            : image_codec.copyResize(normalized, height: _maxDimension);
      }

      // bakeOrientation/copyResize giữ lại EXIF từ ảnh nguồn. Xóa rõ ràng để
      // tọa độ GPS, thông tin thiết bị và các metadata riêng tư không được
      // ghi vào JPEG minh chứng.
      normalized.exif.clear();
      final jpegBytes = image_codec.encodeJpg(normalized, quality: 85);
      if (jpegBytes.length > ImagePickerService.maxFileSizeBytes) {
        throw const ScheduleProofException(
          ScheduleProofErrorCode.imageTooLarge,
          'Ảnh minh chứng vượt quá 5 MB. Bạn chụp lại ảnh gọn hơn nhé.',
        );
      }

      final root = await _rootDirectory();
      final proofDirectory = Directory(
        path.join(root.path, proofDirectoryName),
      );
      await proofDirectory.create(recursive: true);
      final timestamp = _now().toUtc().microsecondsSinceEpoch;
      final filename = 'schedule_${_safeFilenamePart(itemId)}_$timestamp.jpg';
      final destination = File(path.join(proofDirectory.path, filename));
      await destination.writeAsBytes(jpegBytes, flush: true);
      return '$proofDirectoryName/$filename';
    } on ScheduleProofException {
      rethrow;
    } catch (_) {
      throw const ScheduleProofException(
        ScheduleProofErrorCode.cannotSave,
        'Nabi chưa thể lưu ảnh minh chứng lúc này. Mình thử lại sau nhé.',
      );
    }
  }

  Future<File> resolveProofFile(String storedPath) async {
    final normalized = storedPath.trim();
    if (_isAbsolutePath(normalized)) return File(normalized);
    final root = await _rootDirectory();
    final segments = normalized
        .split(RegExp(r'[\\/]'))
        .where((segment) => segment.isNotEmpty && segment != '..')
        .toList(growable: false);
    return File(path.joinAll([root.path, ...segments]));
  }

  Future<bool> proofExists(String storedPath) async {
    return (await resolveProofFile(storedPath)).exists();
  }

  Future<void> deleteProof(String storedPath) async {
    final normalized = storedPath.trim();
    if (normalized.isEmpty || _isAbsolutePath(normalized)) return;
    final file = await resolveProofFile(normalized);
    if (await file.exists()) await file.delete();
  }

  Future<File> restoreProofFromCloud(
    String storedPath,
    Uint8List cloudBytes,
  ) async {
    final normalizedPath = storedPath.trim().replaceAll('\\', '/');
    if (!normalizedPath.startsWith('$proofDirectoryName/') ||
        normalizedPath.contains('..') ||
        !normalizedPath.toLowerCase().endsWith('.jpg')) {
      throw const ScheduleProofException(
        ScheduleProofErrorCode.cannotSave,
        'Đường dẫn ảnh minh chứng chưa hợp lệ.',
      );
    }
    if (cloudBytes.isEmpty ||
        cloudBytes.length > ImagePickerService.maxFileSizeBytes) {
      throw const ScheduleProofException(
        ScheduleProofErrorCode.invalidImage,
        'Ảnh minh chứng trên đám mây chưa hợp lệ.',
      );
    }

    try {
      final decoded = image_codec.decodeImage(cloudBytes);
      if (decoded == null) {
        throw const ScheduleProofException(
          ScheduleProofErrorCode.invalidImage,
          'Ảnh minh chứng trên đám mây chưa hợp lệ.',
        );
      }
      var normalized = image_codec.bakeOrientation(decoded);
      normalized.exif.clear();
      if (normalized.width > _maxDimension ||
          normalized.height > _maxDimension) {
        normalized = normalized.width >= normalized.height
            ? image_codec.copyResize(normalized, width: _maxDimension)
            : image_codec.copyResize(normalized, height: _maxDimension);
      }
      final jpegBytes = image_codec.encodeJpg(normalized, quality: 85);
      if (jpegBytes.length > ImagePickerService.maxFileSizeBytes) {
        throw const ScheduleProofException(
          ScheduleProofErrorCode.imageTooLarge,
          'Ảnh minh chứng trên đám mây vượt quá 5 MB.',
        );
      }
      final destination = await resolveProofFile(normalizedPath);
      await destination.parent.create(recursive: true);
      await destination.writeAsBytes(jpegBytes, flush: true);
      return destination;
    } on ScheduleProofException {
      rethrow;
    } catch (_) {
      throw const ScheduleProofException(
        ScheduleProofErrorCode.cannotSave,
        'Nabi chưa thể tải lại ảnh minh chứng lúc này.',
      );
    }
  }

  String _safeFilenamePart(String value) {
    final safe = value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return safe.isEmpty ? 'item' : safe;
  }

  bool _isAbsolutePath(String value) {
    return path.isAbsolute(value) || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(value);
  }
}
