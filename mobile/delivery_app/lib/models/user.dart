class User {
  final int id;
  final String email;
  final String role;
  final bool isActive;

  User({required this.id, required this.email, required this.role, required this.isActive});

  // Для ответа от /auth/hello (поле user — это email)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,  // если id нет — ставим 0 (временно)
      email: json['user'] ?? json['email'] ?? '',
      role: json['role'] ?? 'user',
      isActive: json['is_active'] ?? true,
    );
  }
}