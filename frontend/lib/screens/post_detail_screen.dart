import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_html/flutter_html.dart';
import '../config/api_config.dart';
import '../providers/user_provider.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../utils/responsive.dart';

class PostDetailScreen extends StatefulWidget {
  final String? id;

  const PostDetailScreen({super.key, this.id});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _isLoading = true;
  PostModel? _post;
  List<CommentModel> _comments = [];
  final TextEditingController _commentController = TextEditingController();
  
  // 대댓글용 상태
  int? _replyToCommentId;
  String? _replyToAuthorName;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    if (widget.id == null) return;
    setState(() => _isLoading = true);

    final userProvider = context.read<UserProvider>();
    final headers = ApiConfig.getHeaders(userProvider.sessionCookie);

    try {
      // 1. 게시글 상세 조회
      final postRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/posts/${widget.id}'), headers: headers);
      if (postRes.statusCode == 200) {
        final data = jsonDecode(postRes.body)['data'];
        if (data != null) {
          _post = PostModel.fromJson(data);
        }
      }

      // 2. 댓글 목록 조회
      final commentRes = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/comments/post/${widget.id}'), headers: headers);
      if (commentRes.statusCode == 200) {
        final List list = jsonDecode(commentRes.body)['data'];
        _comments = list.map((e) => CommentModel.fromJson(e)).toList();
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Post Detail Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    final userProvider = context.read<UserProvider>();
    final headers = ApiConfig.getHeaders(userProvider.sessionCookie);

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/comments'),
        headers: headers,
        body: jsonEncode({
          'postId': int.parse(widget.id!),
          'parentId': _replyToCommentId,
          'content': _commentController.text.trim(),
        }),
      );

      if (res.statusCode == 200) {
        _commentController.clear();
        setState(() {
          _replyToCommentId = null;
          _replyToAuthorName = null;
        });
        _fetchDetail();
        FocusScope.of(context).unfocus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('댓글 등록에 실패했습니다.')));
      }
    } catch (e) {
      debugPrint('Comment Submit Error: $e');
    }
  }

  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('정말로 이 게시글을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      )
    );

    if (confirm != true) return;

    final userProvider = context.read<UserProvider>();
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/posts/${widget.id}'),
        headers: ApiConfig.getHeaders(userProvider.sessionCookie),
      );
      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('게시글이 삭제되었습니다.')));
        context.pop(); // 목록으로 돌아가기
      }
    } catch (e) {
      debugPrint('Delete Post Error: $e');
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('이 댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      )
    );

    if (confirm != true) return;

    final userProvider = context.read<UserProvider>();
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/comments/$commentId'),
        headers: ApiConfig.getHeaders(userProvider.sessionCookie),
      );
      if (res.statusCode == 200) {
        _fetchDetail();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제 권한이 없습니다.')));
      }
    } catch (e) {
      debugPrint('Delete Comment Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_post == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('게시글을 찾을 수 없습니다.')),
      );
    }

    final post = _post!;
    final currentUser = context.read<UserProvider>().user;
    final isAuthorOrAdmin = currentUser?.role == 1 || currentUser?.userId == post.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('상세현황'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(), // 뒤로가기 시 이전 목록으로
        ),
        actions: [
          if (isAuthorOrAdmin)
            PopupMenuButton(
              icon: const Icon(LucideIcons.moreVertical),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('수정')),
                const PopupMenuItem(value: 'delete', child: Text('삭제', style: TextStyle(color: Colors.red))),
              ],
              onSelected: (val) {
                if (val == 'edit') {
                  // TODO: 글쓰기 화면으로 파라미터 넘겨 수정 진입
                } else if (val == 'delete') {
                  _deletePost();
                }
              },
            ),
        ],
      ),
      body: Center(
        child: Container(
          // 웹에서는 900px 최대 너비 중앙 정렬
          constraints: context.isMobile ? null : const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상단 헤더 (제목, 정보)
                      _buildPostHeader(post),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),

                      // 본문 마크다운/HTML 영역
                      Html(data: post.content ?? ''),
                      const SizedBox(height: 40),

                      // 첨부파일 영역
                      if (post.files.isNotEmpty) _buildAttachmentList(post),
                      const Divider(),

                      // 댓글 리스트
                      const SizedBox(height: 16),
                      Text('댓글 ${_comments.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      ..._comments.map((e) => _buildCommentItem(e, currentUser?.userId, currentUser?.role)),
                    ],
                  ),
                ),
              ),
              // 하단 댓글 입력 영역
              _buildCommentInputBase(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostHeader(PostModel post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (post.boardType == 'ISSUE') ...[
              _buildBadge(post.statusId == 1 ? '진행중' : post.statusId == 2 ? '완료' : '미해결', 
                          post.statusId == 2 ? Colors.green : Colors.orange),
              const SizedBox(width: 8),
              _buildBadge(post.priority == 4 ? '긴급' : post.priority == 3 ? '높음' : '보통', 
                          post.priority == 4 ? Colors.red : Colors.blue, outlined: true),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(post.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(LucideIcons.user, size: 16, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName ?? '알 수 없음', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(post.authorCompany ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(DateFormat('yyyy-MM-dd HH:mm').format(post.createdAt ?? DateTime.now()), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text('조회 ${post.viewCount}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttachmentList(PostModel post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('첨부파일', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...post.files.map((file) => Card(
          elevation: 0,
          color: Colors.grey[100],
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(LucideIcons.file),
            title: Text(file.originalName, style: const TextStyle(fontSize: 14)),
            subtitle: Text('${(file.fileSize / 1024).toStringAsFixed(1)} KB', style: const TextStyle(fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(LucideIcons.download, size: 20),
              onPressed: () {
                // TODO: 파일 다운로드 로직
              },
            ),
          ),
        )),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCommentItem(CommentModel comment, int? currentUserId, int? currentUserRole) {
    bool isMyComment = comment.userId == currentUserId || currentUserRole == 1;
    bool isReply = comment.parentId != null && comment.parentId! > 0;

    if (comment.isDeleted) {
      return Padding(
        padding: EdgeInsets.only(left: isReply ? 32.0 : 0, bottom: 16.0),
        child: const Text('삭제된 댓글입니다.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: isReply ? 40.0 : 0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isReply) const Padding(
                padding: EdgeInsets.only(right: 8.0, top: 2.0),
                child: Icon(LucideIcons.cornerDownRight, size: 16, color: Colors.grey),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('${comment.authorName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 8),
                        Text(DateFormat('MM-dd HH:mm').format(comment.createdAt ?? DateTime.now()), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(comment.content, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              // 대댓글 달기 버튼 (답글)
              if (!isReply)
                InkWell(
                  onTap: () {
                    setState(() {
                      _replyToCommentId = comment.commentId;
                      _replyToAuthorName = comment.authorName;
                    });
                    // Focus textarea (생략)
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('답글', style: TextStyle(fontSize: 12, color: Colors.blue)),
                  ),
                ),
              // 내 댓글이거나 관리자면 삭제
              if (isMyComment)
                InkWell(
                  onTap: () => _deleteComment(comment.commentId),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text('삭제', style: TextStyle(fontSize: 12, color: Colors.red)),
                  ),
                ),
            ],
          ),
          const Divider(height: 24, thickness: 0.5),
        ],
      ),
    );
  }

  Widget _buildCommentInputBase() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 8, top: 8, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 답글 타겟 표시
          if (_replyToCommentId != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$_replyToAuthorName님에게 답글 작성 중...', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() { _replyToCommentId = null; _replyToAuthorName = null; }),
                    child: const Icon(LucideIcons.x, size: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: '댓글을 입력하세요...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey[100], // 라이트/다크 대응은 Theme에서 알아서
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.blue),
                child: IconButton(
                  icon: const Icon(LucideIcons.send, color: Colors.white, size: 18),
                  onPressed: _submitComment,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color, {bool outlined = false}) {
    if (outlined) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
