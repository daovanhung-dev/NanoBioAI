class UserModel {
  final String id;

  UserModel({
    required this.id,
  });

  factory UserModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return UserModel(
      id: map['id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
    };
  }
}