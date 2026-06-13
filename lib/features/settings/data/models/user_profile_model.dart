import '../../domain/entities/user_profile_entity.dart';

/// UserProfileModel extends UserProfileEntity to add data serialization capabilities
/// for converting between entity objects and database/JSON representations.
///
/// This model handles the mapping between the database schema (users + health_profiles tables)
/// and the domain entity.
class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.phone,
    required super.gender,
    required super.birthYear,
    required super.occupation,
    required super.heightCm,
    required super.weightKg,
    required super.bmi,
    super.avatarUrl,
  });

  /// Creates a UserProfileModel from a Map (database row or JSON).
  ///
  /// The map should contain fields from both the users table and health_profiles table:
  /// - id, full_name, email, phone, gender, birth_year, avatar_url (from users)
  /// - occupation, height_cm, weight_kg, bmi (from health_profiles)
  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      gender: map['gender'] as String,
      birthYear: map['birth_year'] as int,
      occupation: map['occupation'] as String,
      heightCm: (map['height_cm'] as num).toDouble(),
      weightKg: (map['weight_kg'] as num).toDouble(),
      bmi: (map['bmi'] as num).toDouble(),
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  /// Creates a UserProfileModel from a UserProfileEntity.
  factory UserProfileModel.fromEntity(UserProfileEntity entity) {
    return UserProfileModel(
      id: entity.id,
      fullName: entity.fullName,
      email: entity.email,
      phone: entity.phone,
      gender: entity.gender,
      birthYear: entity.birthYear,
      occupation: entity.occupation,
      heightCm: entity.heightCm,
      weightKg: entity.weightKg,
      bmi: entity.bmi,
      avatarUrl: entity.avatarUrl,
    );
  }

  /// Converts the model to a Map for database storage or JSON serialization.
  ///
  /// Returns a map with all profile fields using the database column names.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email.isEmpty ? null : email,
      'phone': phone.isEmpty ? null : phone,
      'gender': gender,
      'birth_year': birthYear,
      'occupation': occupation,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'bmi': bmi,
      'avatar_url': avatarUrl,
    };
  }

  /// Calculates BMI from height (cm) and weight (kg).
  ///
  /// BMI = weight (kg) / (height (m))^2
  /// Returns the calculated BMI rounded to 2 decimal places.
  static double calculateBmi(double heightCm, double weightKg) {
    if (heightCm <= 0 || weightKg <= 0) {
      return 0.0;
    }
    final heightM = heightCm / 100;
    final bmiValue = weightKg / (heightM * heightM);
    return double.parse(bmiValue.toStringAsFixed(2));
  }

  /// Returns a new UserProfileModel with calculated BMI based on current height and weight.
  UserProfileModel withCalculatedBmi() {
    return UserProfileModel(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      gender: gender,
      birthYear: birthYear,
      occupation: occupation,
      heightCm: heightCm,
      weightKg: weightKg,
      bmi: calculateBmi(heightCm, weightKg),
      avatarUrl: avatarUrl,
    );
  }

  /// Converts this model to a Map for updating the users table only.
  Map<String, dynamic> toUsersTableMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email.isEmpty ? null : email,
      'phone': phone.isEmpty ? null : phone,
      'gender': gender,
      'birth_year': birthYear,
      'avatar_url': avatarUrl,
    };
  }

  /// Converts this model to a Map for updating the health_profiles table only.
  Map<String, dynamic> toHealthProfilesTableMap() {
    return {
      'user_id': id,
      'occupation': occupation,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'bmi': bmi,
    };
  }
}
