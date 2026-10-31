class VietnamPhoneNumber {
  const VietnamPhoneNumber._();

  static const _authAliasDomain = 'phone.nanobio.invalid';

  static String? normalize(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (!RegExp(r'^[+\d\s().-]+$').hasMatch(trimmed)) return null;
    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('0084')) {
      final local = digits.substring(4);
      return _localToE164(local);
    }
    if (digits.startsWith('84')) {
      return _localToE164(digits.substring(2));
    }
    if (!hasPlus && digits.startsWith('0')) {
      return _localToE164(digits.substring(1));
    }
    return null;
  }

  /// Stable internal Auth identity used while phone verification is disabled.
  /// The application continues to collect and display the member's phone.
  static String authEmail(String normalizedPhone) {
    final digits = normalizedPhone.replaceAll(RegExp(r'\D'), '');
    return 'member-$digits@$_authAliasDomain';
  }

  static String? _localToE164(String local) {
    if (!RegExp(r'^\d{9}$').hasMatch(local)) return null;
    return '+84$local';
  }
}
