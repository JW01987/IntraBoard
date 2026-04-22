class CompanyModel {
  final int companyId;
  final String companyName;
  final int companyType;
  final DateTime? createdAt;

  CompanyModel({
    required this.companyId,
    required this.companyName,
    required this.companyType,
    this.createdAt,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      companyId: json['companyId'],
      companyName: json['companyName'] ?? '',
      companyType: json['companyType'] ?? 2,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}
