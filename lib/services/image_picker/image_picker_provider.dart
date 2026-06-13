import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'image_picker_service.dart';

/// Provider for ImagePickerService
/// Returns a singleton instance of ImagePickerService
final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return ImagePickerService();
});
