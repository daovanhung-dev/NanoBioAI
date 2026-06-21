/// Utility class for validating password-related fields
///
/// Validates requirements 3.4-3.6 for password change functionality
class PasswordValidator {
  // Private constructor to prevent instantiation
  PasswordValidator._();

  /// Validates the current password field
  ///
  /// Requirements:
  /// - Password must not be empty
  ///
  /// Returns error message if invalid, null if valid
  static String? validateCurrentPassword(String password) {
    if (password.trim().isEmpty) {
      return 'Vui lòng nhập mật khẩu hiện tại';
    }
    return null;
  }

  /// Validates the new password field
  ///
  /// Requirements:
  /// - Password must be at least 8 characters long
  ///
  /// Returns error message if invalid, null if valid
  static String? validateNewPassword(String password) {
    if (password.isEmpty) {
      return 'Vui lòng nhập mật khẩu mới';
    }
    if (password.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự';
    }
    return null;
  }

  /// Validates the confirm password field
  ///
  /// Requirements:
  /// - Confirm password must match the new password
  ///
  /// Parameters:
  /// - [confirmPassword]: The password to confirm
  /// - [newPassword]: The new password to match against
  ///
  /// Returns error message if invalid, null if valid
  static String? validateConfirmPassword(
    String confirmPassword,
    String newPassword,
  ) {
    if (confirmPassword.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (confirmPassword != newPassword) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  /// Validates all password fields and returns a map of field-specific errors
  ///
  /// Parameters:
  /// - [currentPassword]: The current password
  /// - [newPassword]: The new password
  /// - [confirmPassword]: The password confirmation
  ///
  /// Returns a `Map<String, String>` where keys are field names and values are error messages
  /// Returns empty map if all validations pass
  static Map<String, String> validateAll({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    final Map<String, String> errors = {};

    final currentError = validateCurrentPassword(currentPassword);
    if (currentError != null) {
      errors['currentPassword'] = currentError;
    }

    final newError = validateNewPassword(newPassword);
    if (newError != null) {
      errors['newPassword'] = newError;
    }

    final confirmError = validateConfirmPassword(confirmPassword, newPassword);
    if (confirmError != null) {
      errors['confirmPassword'] = confirmError;
    }

    return errors;
  }
}
