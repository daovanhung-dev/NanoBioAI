class FitnessTrainingAgeGate {
  const FitnessTrainingAgeGate._();

  static int? ageOn(DateTime? birthDate, DateTime today) {
    if (birthDate == null) return null;
    final date = DateTime(birthDate.year, birthDate.month, birthDate.day);
    final current = DateTime(today.year, today.month, today.day);
    if (date.isAfter(current)) return null;
    var age = current.year - date.year;
    if (current.month < date.month ||
        (current.month == date.month && current.day < date.day)) {
      age--;
    }
    return age;
  }

  static bool isAdult(DateTime? birthDate, DateTime today) {
    final age = ageOn(birthDate, today);
    return age != null && age >= 18;
  }
}
