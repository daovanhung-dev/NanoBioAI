import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/services/auth_validators.dart';

void main() {
  group('AuthValidators', () {
    test('validates email format', () {
      expect(AuthValidators.email(''), isNotNull);
      expect(AuthValidators.email('nami'), isNotNull);
      expect(AuthValidators.email('nami@example.com'), isNull);
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
