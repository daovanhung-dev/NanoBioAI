class UserModel {
  final String id;
  final String? email;
  final String? phone;
  final String? fullName;
  final String? avatarUrl;
  final String? gender;
  final int? birthYear;
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
      createdAt: _readString(map['created_at']),
      updatedAt: _readString(map['updated_at']),
    );
  }

  factory UserModel.fromJson(Map<String, Object?> json) => UserModel.fromMap(json);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'gender': gender,
      'birth_year': birthYear,
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

double? _readDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool _readBool(Object? value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().trim().toLowerCase();
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}
