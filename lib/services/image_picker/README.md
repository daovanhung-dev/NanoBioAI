# ImagePickerService

Service for handling image picking from camera or gallery with validation and local storage.

## Features

- Pick images from camera with permission handling
- Pick images from gallery with permission handling
- Validate image format (PNG/JPEG only)
- Validate image size (max 5MB)
- Save images to local app documents directory
- Detailed validation error messages

## Usage

### Basic Setup

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/services/image_picker/image_picker.dart';

// In your widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagePickerService = ref.read(imagePickerServiceProvider);
    // Use the service
  }
}
```

### Pick from Camera

```dart
final imagePickerService = ref.read(imagePickerServiceProvider);

// Pick image from camera
final XFile? image = await imagePickerService.pickFromCamera();

if (image == null) {
  // User cancelled or permission denied
  return;
}

// Validate the image
final isValid = await imagePickerService.validateImage(image);
if (!isValid) {
  // Get detailed error message
  final error = await imagePickerService.getValidationError(image);
  print('Validation failed: $error');
  return;
}

// Save locally
final savedPath = await imagePickerService.saveImageLocally(image);
print('Image saved to: $savedPath');
```

### Pick from Gallery

```dart
final imagePickerService = ref.read(imagePickerServiceProvider);

// Pick image from gallery
final XFile? image = await imagePickerService.pickFromGallery();

if (image == null) {
  // User cancelled or permission denied
  return;
}

// Validate and save
if (await imagePickerService.validateImage(image)) {
  final savedPath = await imagePickerService.saveImageLocally(image);
  print('Image saved to: $savedPath');
} else {
  final error = await imagePickerService.getValidationError(image);
  print('Validation failed: $error');
}
```

### Complete Example with Error Handling

```dart
Future<String?> pickAndSaveAvatar(WidgetRef ref) async {
  final imagePickerService = ref.read(imagePickerServiceProvider);
  
  try {
    // Show bottom sheet to select source
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text('Camera'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );
    
    if (source == null) return null;
    
    // Pick image based on source
    final XFile? image = source == ImageSource.camera
        ? await imagePickerService.pickFromCamera()
        : await imagePickerService.pickFromGallery();
    
    if (image == null) {
      // User cancelled or permission denied
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected')),
      );
      return null;
    }
    
    // Validate image
    final validationError = await imagePickerService.getValidationError(image);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return null;
    }
    
    // Save image locally
    final savedPath = await imagePickerService.saveImageLocally(image);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Image saved successfully')),
    );
    
    return savedPath;
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
    return null;
  }
}
```

## Validation Rules

- **Allowed formats**: PNG, JPEG (jpg, jpeg)
- **Maximum file size**: 5 MB
- **Image optimization**: Automatically resizes to max 1920x1920 with 85% quality

## Permission Handling

The service automatically requests the following permissions:

- **Camera**: `Permission.camera` - Required for `pickFromCamera()`
- **Photos**: `Permission.photos` - Required for `pickFromGallery()`

If permission is denied, the method returns `null`. You should show a permission explanation dialog to the user in this case.

## Storage Location

Images are saved to:
```
<App Documents Directory>/avatars/avatar_<timestamp>.<extension>
```

For example:
```
/data/user/0/com.example.nano_app/app_flutter/avatars/avatar_1704067200000.jpg
```

## Error Handling

All methods may throw exceptions if something goes wrong. Wrap calls in try-catch blocks:

```dart
try {
  final savedPath = await imagePickerService.saveImageLocally(image);
} catch (e) {
  print('Error saving image: $e');
}
```

## Requirements Satisfied

This service satisfies requirements **2.1-2.9** from the App Settings Implementation spec:

- ✅ 2.1: Present image source options (camera/gallery)
- ✅ 2.2: Request appropriate device permissions
- ✅ 2.3: Open selected image picker
- ✅ 2.4: Validate PNG or JPEG format
- ✅ 2.5: Validate file size < 5MB
- ✅ 2.6: Save image locally and update path
- ✅ 2.7: Display new avatar immediately (caller responsibility)
- ✅ 2.8: Show permission explanation on denial (caller responsibility)
- ✅ 2.9: Show validation error messages
