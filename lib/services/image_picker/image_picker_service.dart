import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

enum ImagePickerFailureKind { pick, save }

/// Lỗi có kiểu và thông điệp an toàn để tầng giao diện có thể hiển thị.
class ImagePickerServiceException implements Exception {
  final ImagePickerFailureKind kind;
  final String userMessage;
  final Object? cause;

  const ImagePickerServiceException({
    required this.kind,
    required this.userMessage,
    this.cause,
  });

  @override
  String toString() => userMessage;
}

/// Service for handling image picking from camera/gallery with validation
class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Maximum allowed image file size in bytes (5MB)
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  /// Allowed image formats
  static const List<String> allowedFormats = ['png', 'jpg', 'jpeg'];

  /// Pick image from camera
  /// Requests camera permission before opening camera
  /// Returns XFile if successful, null if cancelled or permission denied
  Future<XFile?> pickFromCamera() async {
    try {
      // Request camera permission
      final permissionStatus = await Permission.camera.request();

      if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
        return null;
      }

      // Open camera
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      return image;
    } catch (error) {
      throw ImagePickerServiceException(
        kind: ImagePickerFailureKind.pick,
        userMessage:
            'Nabi chưa thể mở máy ảnh lúc này. Bạn kiểm tra quyền máy ảnh rồi thử lại nhé.',
        cause: error,
      );
    }
  }

  /// Pick image from gallery
  /// Requests photo library permission before opening gallery
  /// Returns XFile if successful, null if cancelled or permission denied
  Future<XFile?> pickFromGallery() async {
    try {
      // Request photo library permission
      final permissionStatus = await Permission.photos.request();

      if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
        return null;
      }

      // Open gallery
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      return image;
    } catch (error) {
      throw ImagePickerServiceException(
        kind: ImagePickerFailureKind.pick,
        userMessage:
            'Nabi chưa thể mở thư viện ảnh lúc này. Bạn kiểm tra quyền truy cập rồi thử lại nhé.',
        cause: error,
      );
    }
  }

  /// Validate image format and size
  /// Checks if image is PNG or JPEG and less than 5MB
  /// Returns true if valid, false otherwise
  Future<bool> validateImage(XFile file) async {
    try {
      // Check file format
      final extension = path
          .extension(file.path)
          .toLowerCase()
          .replaceAll('.', '');
      if (!allowedFormats.contains(extension)) {
        return false;
      }

      // Check file size
      final fileSize = await file.length();
      if (fileSize > maxFileSizeBytes) {
        return false;
      }

      return true;
    } catch (e) {
      // Log error if needed
      return false;
    }
  }

  /// Save image to app documents directory
  /// Returns the saved file path
  /// Throws exception if save fails
  Future<String> saveImageLocally(
    XFile file, {
    String directoryName = 'avatars',
    String filenamePrefix = 'avatar',
  }) async {
    try {
      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();

      // Create target subdirectory if it doesn't exist
      final targetDir = Directory('${directory.path}/$directoryName');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // Generate unique filename using timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(file.path);
      final filename =
          '${_safeFilenamePrefix(filenamePrefix)}_$timestamp$extension';
      final filePath = '${targetDir.path}/$filename';

      // Copy file to destination
      final File sourceFile = File(file.path);
      await sourceFile.copy(filePath);

      return filePath;
    } catch (error) {
      throw ImagePickerServiceException(
        kind: ImagePickerFailureKind.save,
        userMessage:
            'Nabi chưa thể lưu ảnh này. Bạn kiểm tra dung lượng rồi thử lại nhé.',
        cause: error,
      );
    }
  }

  String _safeFilenamePrefix(String value) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return normalized.isEmpty ? 'image' : normalized;
  }

  /// Get validation error message for image
  /// Returns error message if invalid, null if valid
  Future<String?> getValidationError(XFile file) async {
    try {
      // Check file format
      final extension = path
          .extension(file.path)
          .toLowerCase()
          .replaceAll('.', '');
      if (!allowedFormats.contains(extension)) {
        return 'Định dạng ảnh chưa phù hợp. Bạn chỉ có thể dùng ảnh PNG hoặc JPEG.';
      }

      // Check file size
      final fileSize = await file.length();
      if (fileSize > maxFileSizeBytes) {
        final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
        return 'Ảnh có dung lượng $fileSizeMB MB, vượt quá giới hạn 5 MB.';
      }

      return null;
    } catch (_) {
      return 'Nabi chưa thể kiểm tra ảnh này. Bạn thử chọn ảnh khác nhé.';
    }
  }
}
