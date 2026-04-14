class PostModel {
  final int? postId;
  final String boardType;
  final int? userId;
  final String title;
  final String? content;
  final int viewCount;
  final String? authorName;
  final String? authorCompany;
  final String? categoryName;
  final int? statusId;
  final int? priority;
  final DateTime? createdAt;

  PostModel({
    this.postId,
    required this.boardType,
    this.userId,
    required this.title,
    this.content,
    required this.viewCount,
    this.authorName,
    this.authorCompany,
    this.categoryName,
    this.statusId,
    this.priority,
    this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      postId: json['postId'],
      boardType: json['boardType'] ?? '',
      userId: json['userId'],
      title: json['title'] ?? '',
      content: json['content'],
      viewCount: json['viewCount'] ?? 0,
      authorName: json['authorName'],
      authorCompany: json['authorCompany'],
      categoryName: json['categoryName'],
      statusId: json['statusId'],
      priority: json['priority'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}
