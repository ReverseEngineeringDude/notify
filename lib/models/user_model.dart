enum UserRole {
  superAdmin,
  wardAdmin,
}

class UserModel {
  final String uid;
  final String email;
  final UserRole role;
  final String? wardId; // Only for WardAdmin
  final String? name;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.wardId,
    this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role.name,
      'wardId': wardId,
      'name': name,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.wardAdmin, // Default safety
      ),
      wardId: map['wardId'],
      name: map['name'],
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    UserRole? role,
    String? wardId,
    String? name,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      wardId: wardId ?? this.wardId,
      name: name ?? this.name,
    );
  }
}
