class User {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? imageUrl;
  final bool isAdmin;

  User({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.imageUrl,
    this.isAdmin = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      imageUrl: json['avatar_url'] as String?,
      isAdmin: json['is_admin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': imageUrl,
      'is_admin': isAdmin,
    };
  }
}