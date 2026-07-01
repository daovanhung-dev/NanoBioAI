import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/settings/utils/profile_validator.dart';

void main() {
  group('ProfileValidator', () {
    test('accepts valid profile fields', () {
      final errors = ProfileValidator.validateAll(
        fullName: 'Nguyen Van A',
        email: 'Nabi@example.com',
        phone: '0912345678',
        heightCm: 170,
        weightKg: 65,
        birthYear: 1992,
      );

      expect(errors, isEmpty);
    });

    test('rejects empty or out-of-range profile fields', () {
      final errors = ProfileValidator.validateAll(
        fullName: ' ',
        email: 'not-an-email',
        phone: '123',
        heightCm: 99,
        weightKg: 29,
        birthYear: 1900,
      );

      expect(
        errors.keys,
        containsAll([
          'fullName',
          'email',
          'phone',
          'height',
          'weight',
          'birthYear',
        ]),
      );
    });

    test('accepts supported Vietnamese phone formats', () {
      expect(ProfileValidator.validatePhone('+84912345678'), isNull);
      expect(ProfileValidator.validatePhone('84912345678'), isNull);
      expect(ProfileValidator.validatePhone('0912 345 678'), isNull);
    });
  });
}
