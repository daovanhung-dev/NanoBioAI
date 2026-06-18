class UserModel {
  final String id;
  final String? email;
  final String? phone;
  final String? fullName;
  final String? avatarUrl;
  final String? gender;
  final int? birthYear;
  final String subscriptionTier;
  final String? createdAt;
  final String? updatedAt;

  const UserModel({
    required this.id,
    this.email,
    this.phone,
    this.fullName,
    this.avatarUrl,
    this.gender,
    this.birthYear,
    this.subscriptionTier = 'free',
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, Object?> map) {
    return UserModel(
      id: _readString(map['id']) ?? '',
      email: _readString(map['email']),
      phone: _readString(map['phone']),
      fullName: _readString(map['full_name']),
      avatarUrl: _readString(map['avatar_url']),
      gender: _readString(map['gender']),
      birthYear: _readInt(map['birth_year']),
      subscriptionTier: _readString(map['subscription_tier']) ?? 'free',
      createdAt: _readString(map['created_at']),
      updatedAt: _readString(map['updated_at']),
    );
  }

  factory UserModel.fromJson(Map<String, Object?> json) =>
      UserModel.fromMap(json);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'gender': gender,
      'birth_year': birthYear,
      'subscription_tier': subscriptionTier,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Map<String, Object?> toJson() => toMap();

  UserModel copyWith({
    String? id,
    String? email,
    String? phone,
    String? fullName,
    String? avatarUrl,
    String? gender,
    int? birthYear,
    String? subscriptionTier,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      birthYear: birthYear ?? this.birthYear,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

String? _readString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _readInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
