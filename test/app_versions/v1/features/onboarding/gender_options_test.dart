import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/constants/gender_options.dart';

void main() {
  test('new onboarding exposes only male and female gender choices', () {
    expect(onboardingGenderOptions.map((option) => option.code), [
      'male',
      'female',
    ]);
    expect(onboardingGenderOptions.map((option) => option.label), ['Nam', 'Nữ']);
  });
}
