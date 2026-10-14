import 'vietnam_phone_number.dart';

class AuthValidators {
  const AuthValidators._();

  static String? phone(String value) {
    if (VietnamPhoneNumber.normalize(value) == null) {
      return 'Bạn nhập số điện thoại Việt Nam hợp lệ nhé.';
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
      return 'Tên hơi dài rồi, bạn rút gọn giúp Nabinhé.';
    }
    return null;
  }

  static String? acceptedTerms(bool value) {
    if (!value) {
      return 'Bạn cần đồng ý điều khoản để Nabitạo tài khoản nhé.';
    }
    return null;
  }
}
