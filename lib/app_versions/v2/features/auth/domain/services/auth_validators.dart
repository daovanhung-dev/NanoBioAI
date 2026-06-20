class AuthValidators {
  const AuthValidators._();

  static String? email(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Bạn cho Nami xin email nhé.';
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(trimmed)) {
      return 'Email này có vẻ chưa đúng, bạn kiểm tra lại giúp mình nhé.';
    }
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return 'Bạn chưa nhập mật khẩu rồi.';
    if (value.length < 8) return 'Mật khẩu cần ít nhất 8 ký tự nhé.';
    return null;
  }

  static String? confirmPassword(String password, String confirmPassword) {
    final passwordError = AuthValidators.password(confirmPassword);
    if (passwordError != null) return passwordError;
    if (password != confirmPassword) {
      return 'Hai mật khẩu chưa khớp, mình kiểm tra lại nhé.';
    }
    return null;
  }

  static String? fullName(String value) {
    final trimmed = value.trim();
    if (trimmed.length > 80) {
      return 'Tên hơi dài rồi, bạn rút gọn giúp Nami nhé.';
    }
    return null;
  }

  static String? acceptedTerms(bool value) {
    if (!value) {
      return 'Bạn cần đồng ý điều khoản để Nami tạo tài khoản nhé.';
    }
    return null;
  }
}
