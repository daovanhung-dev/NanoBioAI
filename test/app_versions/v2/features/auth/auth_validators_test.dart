import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/services/auth_validators.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/services/vietnam_phone_number.dart';

void main() {
  group('AuthValidators', () {
    test('accepts Vietnamese phone formats and rejects invalid values', () {
      expect(AuthValidators.phone(''), isNotNull);
      expect(AuthValidators.phone('0912'), isNotNull);
      expect(AuthValidators.phone('0912 345 678'), isNull);
      expect(AuthValidators.phone('+84 912 345 678'), isNull);
    });

    test('normalizes local and international numbers to E.164', () {
      expect(VietnamPhoneNumber.normalize('0912 345 678'), '+84912345678');
      expect(VietnamPhoneNumber.normalize('84 912 345 678'), '+84912345678');
      expect(VietnamPhoneNumber.normalize('+84 912 345 678'), '+84912345678');
      expect(
        VietnamPhoneNumber.authEmail('+84912345678'),
        'member-84912345678@phone.nanobio.invalid',
      );
      expect(VietnamPhoneNumber.normalize('123'), isNull);
    });

    test('requires at least 8 password characters', () {
      expect(AuthValidators.password('1234567'), isNotNull);
      expect(AuthValidators.password('12345678'), isNull);
    });

    test('requires matching password confirmation', () {
      expect(AuthValidators.confirmPassword('12345678', '12345670'), isNotNull);
      expect(AuthValidators.confirmPassword('12345678', '12345678'), isNull);
    });

    test('requires accepted terms', () {
      expect(AuthValidators.acceptedTerms(false), isNotNull);
      expect(AuthValidators.acceptedTerms(true), isNull);
    });
  });
}
