class UserModel {
  final Long? userId;
  final String name;
  final int role;
  final Long companyId;

  UserModel({
    this.userId,
    required this.name,
    required this.role,
    required this.companyId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'],
      name: json['name'] ?? '',
      role: json['role'] ?? 2,
      companyId: json['companyId'],
    );
  }
}

// Dart에는 Long이 없으므로 int 혹은 dynamic 처리
typedef Long = dynamic;
