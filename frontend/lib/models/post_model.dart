import 'post_file_model.dart';

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
  final int? categoryId;
  final int? statusId;
  final int? priority;
  final int? assignedUserId;
  final String? assignedUserName;
  final DateTime? createdAt;
  final List<PostFileModel> files;

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
    this.categoryId,
    this.statusId,
    this.priority,
    this.assignedUserId,
    this.assignedUserName,
    this.createdAt,
    this.files = const [],
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
      categoryId: json['categoryId'],
      statusId: json['statusId'],
      priority: json['priority'],
      assignedUserId: json['assignedUserId'],
      assignedUserName: json['assignedUserName'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      files: json['files'] != null
          ? (json['files'] as List)
              .map((e) => PostFileModel.fromJson(e))
              .toList()
          : [],
    );
  }
}
