class CompanyModel {
  final int companyId;
  final String companyName;
  final int companyType;

  CompanyModel({
    required this.companyId,
    required this.companyName,
    required this.companyType,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      companyId: json['companyId'],
      companyName: json['companyName'] ?? '',
      companyType: json['companyType'] ?? 2,
    );
  }
}
