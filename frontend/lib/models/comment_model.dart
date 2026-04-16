class CommentModel {
  final int commentId;
  final int postId;
  final int userId;
  final int? parentId;
  final String content;
  final bool isDeleted;
  final String? authorName;
  final String? authorCompany;
  final int? authorRole;
  final DateTime? createdAt;

  CommentModel({
    required this.commentId,
    required this.postId,
    required this.userId,
    this.parentId,
    required this.content,
    required this.isDeleted,
    this.authorName,
    this.authorCompany,
    this.authorRole,
    this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      commentId: json['commentId'],
      postId: json['postId'],
      userId: json['userId'],
      parentId: json['parentId'],
      content: json['content'] ?? '',
      isDeleted: json['isDeleted'] ?? false,
      authorName: json['authorName'],
      authorCompany: json['authorCompany'],
      authorRole: json['authorRole'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}
