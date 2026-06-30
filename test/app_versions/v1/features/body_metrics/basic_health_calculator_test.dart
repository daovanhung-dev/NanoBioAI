import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/entities/basic_health_calculator_models.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/domain/services/basic_health_calculator.dart';

void main() {
  group('BasicHealthCalculator', () {
    test('calculates BMI, BMR, RMR, TDEE, hydration and guidance', () {
      final report = BasicHealthCalculator.calculate(
        const BasicHealthInput(
          heightCm: 170,
          weightKg: 65,
          ageYears: 30,
          sex: BasicHealthSex.female,
          activityLevel: BasicHealthActivityLevel.moderate,
        ),
      );

      expect(report.formulaVersion, basicHealthCalculatorVersion);
      expect(report.bmi, 22.5);
      expect(report.bmiCategory, 'Can doi');
      expect(report.bmrKcal, 1402);
      expect(report.rmrKcal, 1472);
      expect(report.tdeeKcal, 2172);
      expect(report.hydrationMl, 2275);
      expect(report.sleepGuidance, contains('7-9 gio'));
      expect(report.activityGuidance, contains('150 phut'));
    });

    test('rejects invalid input ranges', () {
      expect(
        () => BasicHealthCalculator.calculate(
          const BasicHealthInput(
            heightCm: 40,
            weightKg: 65,
            ageYears: 30,
            sex: BasicHealthSex.male,
            activityLevel: BasicHealthActivityLevel.light,
          ),
        ),
        throwsA(isA<BasicHealthCalculatorException>()),
      );
    });
  });
}
