class UserModel {
  final Long? userId;
  final String? loginId;
  final String name;
  final int role;
  final Long companyId;
  final String? companyName;
  final int? companyType; // 추가
  final DateTime? createdAt;
  final int? status;

  UserModel({
    this.userId,
    this.loginId,
    required this.name,
    required this.role,
    required this.companyId,
    this.companyName,
    this.companyType, // 추가
    this.createdAt,
    this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'],
      loginId: json['loginId'],
      name: json['name'] ?? '',
      role: json['role'] ?? 2,
      companyId: json['companyId'],
      companyName: json['companyName'],
      companyType: json['companyType'], // 추가
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      status: json['status'] ?? 0,
    );
  }
}

// Dart에는 Long이 없으므로 int 혹은 dynamic 처리
typedef Long = dynamic;
