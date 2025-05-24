class UserModel {
  final String id;
  final String username;
  final String avatar;
  final String email;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.avatar = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      avatar: json['avatar'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar': avatar,
      'email': email,
    };
  }

  @override
  String toString() {
    return 'UserModel{id: $id, username: $username, avatar: $avatar, email: $email}';
  }
}
