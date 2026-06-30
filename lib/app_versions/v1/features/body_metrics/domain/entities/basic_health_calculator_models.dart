const basicHealthCalculatorVersion = 'm04_basic_health_v1_2026_06';

enum BasicHealthSex {
  female('female', 'Nu'),
  male('male', 'Nam');

  final String code;
  final String label;

  const BasicHealthSex(this.code, this.label);
}

enum BasicHealthActivityLevel {
  sedentary('sedentary', 'It van dong', 1.2),
  light('light', 'Van dong nhe', 1.375),
  moderate('moderate', 'Van dong vua', 1.55),
  active('active', 'Van dong cao', 1.725);

  final String code;
  final String label;
  final double multiplier;

  const BasicHealthActivityLevel(this.code, this.label, this.multiplier);
}

class BasicHealthInput {
  final double heightCm;
  final double weightKg;
  final int ageYears;
  final BasicHealthSex sex;
  final BasicHealthActivityLevel activityLevel;

  const BasicHealthInput({
    required this.heightCm,
    required this.weightKg,
    required this.ageYears,
    required this.sex,
    required this.activityLevel,
  });
}

class BasicHealthReport {
  final String formulaVersion;
  final double bmi;
  final String bmiCategory;
  final int bmrKcal;
  final int rmrKcal;
  final int tdeeKcal;
  final int hydrationMl;
  final String sleepGuidance;
  final String activityGuidance;

  const BasicHealthReport({
    required this.formulaVersion,
    required this.bmi,
    required this.bmiCategory,
    required this.bmrKcal,
    required this.rmrKcal,
    required this.tdeeKcal,
    required this.hydrationMl,
    required this.sleepGuidance,
    required this.activityGuidance,
  });
}

class BasicHealthCalculatorException implements Exception {
  final String message;

  const BasicHealthCalculatorException(this.message);

  @override
  String toString() => message;
}
