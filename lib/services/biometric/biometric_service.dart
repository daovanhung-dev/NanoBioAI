import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

/// Exception thrown when biometric authentication fails
class BiometricException implements Exception {
  final String message;
  final String? code;

  const BiometricException(this.message, {this.code});

  @override
  String toString() => 'BiometricException: $message';
}

/// Service for handling biometric authentication (Face ID, Touch ID, Fingerprint)
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Checks if biometric authentication is available on the device
  /// 
  /// Returns true if:
  /// - Device has biometric hardware
  /// - Device has at least one enrolled biometric (fingerprint, face, etc.)
  /// 
  /// Requirements: 4.1, 4.2, 4.7
  Future<bool> isAvailable() async {
    try {
      // Check if device can check biometrics
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      
      // Check if device is capable (has hardware)
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      
      // Return true only if both hardware exists and biometrics can be checked
      return canCheckBiometrics && isDeviceSupported;
    } on PlatformException catch (e) {
      throw BiometricException(
        'Failed to check biometric availability: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw BiometricException(
        'Unexpected error checking biometric availability: $e',
      );
    }
  }

  /// Triggers biometric authentication with the given reason
  /// 
  /// [reason] - The message displayed to the user explaining why authentication is needed
  /// 
  /// Returns true if authentication succeeds, false if it fails or is cancelled
  /// 
  /// Throws [BiometricException] for errors other than authentication failure
  /// 
  /// Requirements: 4.4, 4.5, 4.8
  Future<bool> authenticate(String reason) async {
    try {
      // Check if biometrics are available first
      final bool available = await isAvailable();
      
      if (!available) {
        throw BiometricException(
          'Biometric authentication is not available on this device',
        );
      }

      // Attempt authentication
      final bool authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true, // Keep auth dialog on screen if app goes to background
          biometricOnly: true, // Only use biometrics, not device PIN
        ),
      );

      return authenticated;
    } on PlatformException catch (e) {
      // Handle specific error codes
      switch (e.code) {
        case auth_error.notAvailable:
          throw BiometricException(
            'Biometric authentication is not available',
            code: e.code,
          );
        case auth_error.notEnrolled:
          throw BiometricException(
            'No biometrics enrolled on this device',
            code: e.code,
          );
        case auth_error.passcodeNotSet:
          throw BiometricException(
            'Device passcode is not set',
            code: e.code,
          );
        case auth_error.lockedOut:
          throw BiometricException(
            'Biometric authentication is locked due to too many failed attempts',
            code: e.code,
          );
        case auth_error.permanentlyLockedOut:
          throw BiometricException(
            'Biometric authentication is permanently locked',
            code: e.code,
          );
        default:
          // User cancelled or authentication failed - return false instead of throwing
          if (e.code == 'AuthenticationFailed' || e.code == 'UserCancel') {
            return false;
          }
          throw BiometricException(
            'Biometric authentication error: ${e.message}',
            code: e.code,
          );
      }
    } catch (e) {
      if (e is BiometricException) {
        rethrow;
      }
      throw BiometricException(
        'Unexpected error during biometric authentication: $e',
      );
    }
  }

  /// Gets the list of available biometric types on the device
  /// 
  /// Returns a list of available biometric types (fingerprint, face, iris, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      throw BiometricException(
        'Failed to get available biometrics: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw BiometricException(
        'Unexpected error getting available biometrics: $e',
      );
    }
  }
}
