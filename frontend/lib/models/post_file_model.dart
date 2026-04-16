class PostFileModel {
  final int fileId;
  final int postId;
  final String originalName;
  final String savedName;
  final String filePath;
  final int fileSize;
  final DateTime? createdAt;

  PostFileModel({
    required this.fileId,
    required this.postId,
    required this.originalName,
    required this.savedName,
    required this.filePath,
    required this.fileSize,
    this.createdAt,
  });

  factory PostFileModel.fromJson(Map<String, dynamic> json) {
    return PostFileModel(
      fileId: json['fileId'],
      postId: json['postId'],
      originalName: json['originalName'] ?? '',
      savedName: json['savedName'] ?? '',
      filePath: json['filePath'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}
