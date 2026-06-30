import '../entities/basic_health_calculator_models.dart';

class BasicHealthCalculator {
  const BasicHealthCalculator._();

  static BasicHealthReport calculate(BasicHealthInput input) {
    _validate(input);

    final heightM = input.heightCm / 100;
    final bmi = input.weightKg / (heightM * heightM);
    final sexOffset = input.sex == BasicHealthSex.male ? 5 : -161;
    final bmr =
        10 * input.weightKg +
        6.25 * input.heightCm -
        5 * input.ageYears +
        sexOffset;
    final rmr = bmr * 1.05;
    final tdee = bmr * input.activityLevel.multiplier;
    final hydrationMl = (input.weightKg * 35).round();

    return BasicHealthReport(
      formulaVersion: basicHealthCalculatorVersion,
      bmi: double.parse(bmi.toStringAsFixed(1)),
      bmiCategory: _bmiCategory(bmi),
      bmrKcal: bmr.round(),
      rmrKcal: rmr.round(),
      tdeeKcal: tdee.round(),
      hydrationMl: hydrationMl,
      sleepGuidance: 'Nguoi truong thanh nen uu tien 7-9 gio ngu moi dem.',
      activityGuidance:
          'Dat muc tieu toi thieu 150 phut van dong vua moi tuan, tang dan theo the luc.',
    );
  }

  static void _validate(BasicHealthInput input) {
    if (input.heightCm < 80 || input.heightCm > 230) {
      throw const BasicHealthCalculatorException(
        'Chieu cao can nam trong khoang 80-230 cm.',
      );
    }
    if (input.weightKg < 20 || input.weightKg > 300) {
      throw const BasicHealthCalculatorException(
        'Can nang can nam trong khoang 20-300 kg.',
      );
    }
    if (input.ageYears < 13 || input.ageYears > 100) {
      throw const BasicHealthCalculatorException(
        'Tuoi can nam trong khoang 13-100.',
      );
    }
  }

  static String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Thieu can';
    if (bmi < 23) return 'Can doi';
    if (bmi < 25) return 'Thua can';
    return 'Can theo doi beo phi';
  }
}
