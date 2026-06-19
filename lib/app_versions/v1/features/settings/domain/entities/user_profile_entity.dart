/// UserProfileEntity represents the complete user profile information
/// combining personal details from the users table and health metrics
/// from the health_profiles table.
///
/// This is a pure Dart entity with no external dependencies, following
/// Clean Architecture principles.
class UserProfileEntity {
  /// Unique identifier for the user
  final String id;

  /// User's full name
  final String fullName;

  /// User's email address
  final String email;

  /// User's phone number
  final String phone;

  /// User's gender (e.g., 'male', 'female', 'other')
  final String gender;

  /// Year the user was born
  final int birthYear;

  /// User's occupation or profession
  final String occupation;

  /// User's height in centimeters
  final double heightCm;

  /// User's weight in kilograms
  final double weightKg;

  /// User's Body Mass Index (calculated from height and weight)
  final double bmi;

  /// Account or app plan tier stored on the local users table.
  final String subscriptionTier;

  /// Optional URL or local path to the user's avatar image
  final String? avatarUrl;

  const UserProfileEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.gender,
    required this.birthYear,
    required this.occupation,
    required this.heightCm,
    required this.weightKg,
    required this.bmi,
    this.subscriptionTier = 'free',
    this.avatarUrl,
  });

  /// Creates a copy of this entity with optionally modified fields
  UserProfileEntity copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? gender,
    int? birthYear,
    String? occupation,
    double? heightCm,
    double? weightKg,
    double? bmi,
    String? subscriptionTier,
    String? avatarUrl,
  }) {
    return UserProfileEntity(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      birthYear: birthYear ?? this.birthYear,
      occupation: occupation ?? this.occupation,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      bmi: bmi ?? this.bmi,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserProfileEntity &&
        other.id == id &&
        other.fullName == fullName &&
        other.email == email &&
        other.phone == phone &&
        other.gender == gender &&
        other.birthYear == birthYear &&
        other.occupation == occupation &&
        other.heightCm == heightCm &&
        other.weightKg == weightKg &&
        other.bmi == bmi &&
        other.subscriptionTier == subscriptionTier &&
        other.avatarUrl == avatarUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      fullName,
      email,
      phone,
      gender,
      birthYear,
      occupation,
      heightCm,
      weightKg,
      bmi,
      subscriptionTier,
      avatarUrl,
    );
  }

  @override
  String toString() {
    return 'UserProfileEntity(id: $id, fullName: $fullName, email: $email, '
        'phone: $phone, gender: $gender, birthYear: $birthYear, '
        'occupation: $occupation, heightCm: $heightCm, weightKg: $weightKg, '
        'bmi: $bmi, subscriptionTier: $subscriptionTier, avatarUrl: $avatarUrl)';
  }
}
