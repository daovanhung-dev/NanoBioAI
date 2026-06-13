# Biometric Service

Service for handling biometric authentication (Face ID, Touch ID, Fingerprint) in the BioAI app.

## Overview

The `BiometricService` provides a simple interface to check device biometric capabilities and authenticate users using their device's biometric hardware.

## Features

- ✅ Check biometric availability on device
- ✅ Trigger biometric authentication with custom reason
- ✅ Get list of available biometric types
- ✅ Comprehensive error handling with `BiometricException`
- ✅ Support for Face ID, Touch ID, and Fingerprint

## Requirements

This service requires the following platform configurations:

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSFaceIDUsageDescription</key>
<string>We use Face ID to secure your app access</string>
```

## Usage

### Check if Biometrics are Available

```dart
import 'package:nano_app/services/biometric/biometric_service.dart';

final biometricService = BiometricService();

try {
  final isAvailable = await biometricService.isAvailable();
  
  if (isAvailable) {
    print('Biometric authentication is available');
  } else {
    print('Biometric authentication is not available');
  }
} on BiometricException catch (e) {
  print('Error checking biometric availability: ${e.message}');
}
```

### Authenticate User

```dart
try {
  final authenticated = await biometricService.authenticate(
    'Please authenticate to access settings',
  );
  
  if (authenticated) {
    print('Authentication successful');
    // Enable biometric login in settings
  } else {
    print('Authentication failed or cancelled');
    // Keep biometric toggle disabled
  }
} on BiometricException catch (e) {
  print('Biometric authentication error: ${e.message}');
  
  if (e.code == 'notEnrolled') {
    // Show message: "No biometrics enrolled on device"
  } else if (e.code == 'lockedOut') {
    // Show message: "Too many failed attempts. Try again later."
  }
}
```

### Get Available Biometric Types

```dart
try {
  final biometricTypes = await biometricService.getAvailableBiometrics();
  
  for (final type in biometricTypes) {
    print('Available: ${type.name}');
  }
  
  // BiometricType values:
  // - face (Face ID)
  // - fingerprint (Touch ID/Fingerprint)
  // - iris (Iris scanner)
  // - weak (Device PIN/Pattern)
  // - strong (Strong biometric)
} on BiometricException catch (e) {
  print('Error: ${e.message}');
}
```

## Error Handling

The service throws `BiometricException` for errors. Common error codes:

| Code | Description | Action |
|------|-------------|--------|
| `notAvailable` | Biometric auth not available | Hide biometric option |
| `notEnrolled` | No biometrics enrolled | Prompt user to enroll |
| `passcodeNotSet` | Device passcode not set | Prompt to set passcode |
| `lockedOut` | Too many failed attempts | Show temporary lockout message |
| `permanentlyLockedOut` | Permanently locked | Direct to settings |

### Example Error Handling

```dart
try {
  final result = await biometricService.authenticate('Login');
  // Handle success
} on BiometricException catch (e) {
  switch (e.code) {
    case 'notEnrolled':
      showDialog(
        message: 'Please enroll your fingerprint or Face ID in device settings',
      );
      break;
    case 'lockedOut':
      showDialog(
        message: 'Too many failed attempts. Please try again later.',
      );
      break;
    default:
      showDialog(message: e.message);
  }
}
```

## Integration with Settings Feature

The BiometricService is used in the Security settings to:

1. Check if biometric toggle should be displayed (Requirements 4.1-4.2)
2. Request biometric authentication when enabling the feature (Requirements 4.4-4.5)
3. Handle authentication failures with appropriate error messages (Requirements 4.7-4.8)

### Example: Settings Integration

```dart
// In SecurityController
Future<void> toggleBiometric(bool enabled) async {
  if (enabled) {
    try {
      // Check availability first
      final isAvailable = await biometricService.isAvailable();
      if (!isAvailable) {
        throw BiometricException('Biometric authentication not available');
      }
      
      // Request authentication
      final authenticated = await biometricService.authenticate(
        'Enable biometric authentication',
      );
      
      if (authenticated) {
        // Save enabled state to SharedPreferences
        await repository.updateBiometric(true);
        state = state.copyWith(biometricEnabled: true);
      }
    } on BiometricException catch (e) {
      // Show error to user
      _showError(e.message);
    }
  } else {
    // Disable biometric (no auth needed)
    await repository.updateBiometric(false);
    state = state.copyWith(biometricEnabled: false);
  }
}
```

## Testing

The service includes unit tests for:
- ✅ Service instantiation
- ✅ BiometricException creation and properties
- ✅ API contract (method existence)

Note: Full integration testing requires a device/emulator with biometric hardware. Unit tests focus on structure and exception handling.

## Dependencies

- `local_auth: ^2.2.0` - Flutter plugin for local authentication

## Requirements Covered

This implementation satisfies the following requirements:

- **4.1**: Check device biometric availability
- **4.2**: Display biometric toggle when device supports biometrics
- **4.4**: Request biometric authentication when enabling
- **4.5**: Save enabled state on successful authentication
- **4.7**: Hide toggle when device doesn't support biometrics
- **4.8**: Display error message on authentication failure

## See Also

- [Settings Feature Design](../../.kiro/specs/app-settings-implementation/design.md)
- [Requirements Document](../../.kiro/specs/app-settings-implementation/requirements.md)
- [local_auth package](https://pub.dev/packages/local_auth)
