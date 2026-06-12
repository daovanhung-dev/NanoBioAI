// lib/core/interfaces/health_data_interface.dart

/// Abstract interface for health data to enable dependency inversion.
/// Services can depend on this interface instead of concrete feature entities.
abstract class HealthDataInterface {
  String get fullName;
  String get gender;
  int get birthYear;
  double get heightCm;
  double get weightKg;
  double get bmi;
  List<String> get goals;
  List<String> get conditions;
  List<String> get habits;
  String get sleepQuality;
  String get activityLevel;
  String get waterPerDay;
  String get allergyName;
  String get allergyNote;
  String get treatmentName;
  String get medicationName;
  String get treatmentNote;
  String get concernText;
}
