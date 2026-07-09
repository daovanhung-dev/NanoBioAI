import 'package:nano_app/services/image_picker/image_picker_service.dart';

class ScheduleProofImageService {
  final ImagePickerService imagePickerService;

  const ScheduleProofImageService({required this.imagePickerService});

  Future<String?> captureProofForItem(String itemId) async {
    final image = await imagePickerService.pickFromCamera();
    if (image == null) return null;

    final validationError = await imagePickerService.getValidationError(image);
    if (validationError != null) {
      throw StateError(validationError);
    }

    return imagePickerService.saveImageLocally(
      image,
      directoryName: 'schedule_proofs',
      filenamePrefix: 'schedule_$itemId',
    );
  }
}
