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
      sleepGuidance: 'Người trưởng thành nên ưu tiên 7–9 giờ ngủ mỗi đêm.',
      activityGuidance:
          'Đặt mục tiêu tối thiểu 150 phút vận động vừa mỗi tuần, tăng dần theo thể lực.',
    );
  }

  static void _validate(BasicHealthInput input) {
    if (input.heightCm < 80 || input.heightCm > 230) {
      throw const BasicHealthCalculatorException(
        'Chiều cao cần nằm trong khoảng 80–230 cm.',
      );
    }
    if (input.weightKg < 20 || input.weightKg > 300) {
      throw const BasicHealthCalculatorException(
        'Cân nặng cần nằm trong khoảng 20–300 kg.',
      );
    }
    if (input.ageYears < 13 || input.ageYears > 100) {
      throw const BasicHealthCalculatorException(
        'Tuổi cần nằm trong khoảng 13–100.',
      );
    }
  }

  static String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 23) return 'Cân đối';
    if (bmi < 25) return 'Thừa cân';
    return 'Cần theo dõi béo phì';
  }
}
