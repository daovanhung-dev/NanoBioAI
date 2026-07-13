/// Validator for settings-related values.
///
/// This class provides validation methods for app settings including:
/// - Meal reminder time format validation
/// - Language code validation
class SettingsValidator {
  SettingsValidator._();

  /// Validates meal reminder time format.
  ///
  /// Checks if the time string is in valid HH:mm format where:
  /// - HH is 00-23 (24-hour format)
  /// - mm is 00-59
  ///
  /// Returns null if valid, otherwise returns an error message.
  ///
  /// Examples:
  /// - "09:30" -> null (valid)
  /// - "23:59" -> null (valid)
  /// - "24:00" -> error (invalid hour)
  /// - "12:60" -> error (invalid minute)
  /// - "9:30" -> error (missing leading zero)
  /// - "12-30" -> error (wrong separator)
  static String? validateMealReminderTime(String? time) {
    if (time == null || time.isEmpty) {
      return 'Thời gian nhắc nhở không được để trống';
    }

    // Check basic format: must be exactly 5 characters
    if (time.length != 5) {
      return 'Thời gian phải có định dạng HH:mm (ví dụ: 09:30)';
    }

    // Check format using regex: HH:mm
    final timeRegex = RegExp(r'^([0-1][0-9]|2[0-3]):([0-5][0-9])$');
    if (!timeRegex.hasMatch(time)) {
      return 'Thời gian phải có định dạng HH:mm với giờ từ 00-23 và phút từ 00-59';
    }

    return null;
  }

  /// Validates language code.
  ///
  /// Checks that the language code is Vietnamese (`vi`).
  ///
  /// Returns null if valid, otherwise returns an error message.
  ///
  /// Examples:
  /// - "vi" -> null (valid)
  /// - "en" -> error (not supported)
  /// - "fr" -> error (not supported)
  /// - "" -> error (empty)
  static String? validateLanguageCode(String? code) {
    if (code == null || code.isEmpty) {
      return 'Mã ngôn ngữ không được để trống';
    }

    if (code != 'vi') {
      return 'Ứng dụng hiện chỉ hỗ trợ giao diện tiếng Việt';
    }

    return null;
  }

  /// Validates all meal reminder settings.
  ///
  /// Returns a map of field names to error messages.
  /// Empty map indicates all validations passed.
  static Map<String, String> validateMealReminderSettings({
    required String? time,
  }) {
    final errors = <String, String>{};

    final timeError = validateMealReminderTime(time);
    if (timeError != null) {
      errors['meal_reminder_time'] = timeError;
    }

    return errors;
  }

  /// Validates all language settings.
  ///
  /// Returns a map of field names to error messages.
  /// Empty map indicates all validations passed.
  static Map<String, String> validateLanguageSettings({
    required String? languageCode,
  }) {
    final errors = <String, String>{};

    final codeError = validateLanguageCode(languageCode);
    if (codeError != null) {
      errors['language_code'] = codeError;
    }

    return errors;
  }
}
