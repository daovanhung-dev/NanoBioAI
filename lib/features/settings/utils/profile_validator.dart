/// Profile validation utility class for the Settings feature
///
/// This class provides static validation methods for user profile fields,
/// returning specific error messages for each validation failure.
class ProfileValidator {
  ProfileValidator._();

  /// Validates height is within acceptable range (100-250cm)
  ///
  /// Returns error message if invalid, null if valid.
  static String? validateHeight(double? heightCm) {
    if (heightCm == null) {
      return 'Chiều cao không được để trống';
    }
    if (heightCm < 100) {
      return 'Chiều cao phải từ 100cm trở lên';
    }
    if (heightCm > 250) {
      return 'Chiều cao phải nhỏ hơn hoặc bằng 250cm';
    }
    return null;
  }

  /// Validates weight is within acceptable range (30-300kg)
  ///
  /// Returns error message if invalid, null if valid.
  static String? validateWeight(double? weightKg) {
    if (weightKg == null) {
      return 'Cân nặng không được để trống';
    }
    if (weightKg < 30) {
      return 'Cân nặng phải từ 30kg trở lên';
    }
    if (weightKg > 300) {
      return 'Cân nặng phải nhỏ hơn hoặc bằng 300kg';
    }
    return null;
  }

  /// Validates birth year is greater than 1900 and not in the future
  ///
  /// Returns error message if invalid, null if valid.
  static String? validateBirthYear(int? birthYear) {
    if (birthYear == null) {
      return 'Năm sinh không được để trống';
    }
    if (birthYear <= 1900) {
      return 'Năm sinh phải lớn hơn 1900';
    }
    final currentYear = DateTime.now().year;
    if (birthYear > currentYear) {
      return 'Năm sinh không thể lớn hơn năm hiện tại';
    }
    return null;
  }

  /// Validates full name is not empty
  ///
  /// Returns error message if invalid, null if valid.
  static String? validateFullName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return 'Họ và tên không được để trống';
    }
    return null;
  }

  /// Validates email format using regex pattern
  ///
  /// Returns error message if invalid, null if valid.
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email không được để trống';
    }
    
    // Email regex pattern: basic format validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Email không đúng định dạng';
    }
    
    return null;
  }

  /// Validates phone number format
  ///
  /// Checks for basic phone format (10-11 digits, optional +84 prefix)
  /// Returns error message if invalid, null if valid.
  static String? validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'Số điện thoại không được để trống';
    }
    
    final cleanPhone = phone.trim().replaceAll(RegExp(r'[\s-]'), '');
    
    // Phone regex pattern: supports Vietnamese phone numbers
    // Formats: 0xxxxxxxxx (10 digits), 84xxxxxxxxx (11 digits), +84xxxxxxxxx
    final phoneRegex = RegExp(
      r'^(\+?84|0)[0-9]{9}$',
    );
    
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Số điện thoại không đúng định dạng';
    }
    
    return null;
  }

  /// Validates all profile fields and returns a map of field-specific errors
  ///
  /// Returns a Map<String, String> where:
  /// - Key: field name (e.g., 'height', 'weight', 'fullName')
  /// - Value: error message
  ///
  /// Returns empty map if all validations pass.
  static Map<String, String> validateAll({
    String? fullName,
    String? email,
    String? phone,
    double? heightCm,
    double? weightKg,
    int? birthYear,
  }) {
    final errors = <String, String>{};

    final fullNameError = validateFullName(fullName);
    if (fullNameError != null) {
      errors['fullName'] = fullNameError;
    }

    final emailError = validateEmail(email);
    if (emailError != null) {
      errors['email'] = emailError;
    }

    final phoneError = validatePhone(phone);
    if (phoneError != null) {
      errors['phone'] = phoneError;
    }

    final heightError = validateHeight(heightCm);
    if (heightError != null) {
      errors['height'] = heightError;
    }

    final weightError = validateWeight(weightKg);
    if (weightError != null) {
      errors['weight'] = weightError;
    }

    final birthYearError = validateBirthYear(birthYear);
    if (birthYearError != null) {
      errors['birthYear'] = birthYearError;
    }

    return errors;
  }
}
