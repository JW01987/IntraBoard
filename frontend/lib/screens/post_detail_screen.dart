import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../providers/user_provider.dart';
import '../models/post_model.dart';
import '../models/post_file_model.dart';
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

  // 댓글 스크롤 이동 및 포커스를 위한 상태
  final Map<int, GlobalKey> _commentKeys = {};
  int? _highlightedCommentId;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  void _scrollToAndHighlightComment(int commentId) {
    final targetKey = _commentKeys[commentId];
    if (targetKey != null && targetKey.currentContext != null) {
      Scrollable.ensureVisible(
        targetKey.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.5, // 0.5 = 화면 수직 중앙 정렬
      );

      setState(() {
        _highlightedCommentId = commentId;
      });

      // 1.5초 후 배경 하이라이트 효과 원상복구
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && _highlightedCommentId == commentId) {
          setState(() {
            _highlightedCommentId = null;
          });
        }
      });
    }
  }

  Future<void> _fetchDetail() async {
    if (widget.id == null) return;
    setState(() => _isLoading = true);

    final userProvider = context.read<UserProvider>();
    final headers = ApiConfig.getHeaders(userProvider.sessionCookie);

    try {
      // 1. 게시글 상세 조회
      final postRes = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/posts/${widget.id}'),
          headers: headers);
      if (!mounted) return;
      if (postRes.statusCode == 200) {
        final data = jsonDecode(postRes.body)['data'];
        if (data != null) {
          _post = PostModel.fromJson(data);
        }
      }

      // 2. 댓글 목록 조회
      final commentRes = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/comments/post/${widget.id}'),
          headers: headers);
      if (!mounted) return;
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
      if (!mounted) return;
      if (res.statusCode == 200) {
        _commentController.clear();
        setState(() {
          _replyToCommentId = null;
          _replyToAuthorName = null;
        });
        _fetchDetail();
        FocusScope.of(context).unfocus();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('댓글 등록에 실패했습니다.')));
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
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('취소')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child:
                        const Text('삭제', style: TextStyle(color: Colors.red))),
              ],
            ));

    if (confirm != true) return;

    final userProvider = context.read<UserProvider>();
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/posts/${widget.id}'),
        headers: ApiConfig.getHeaders(userProvider.sessionCookie),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('게시글이 삭제되었습니다.')));
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
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('취소')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child:
                        const Text('삭제', style: TextStyle(color: Colors.red))),
              ],
            ));

    if (confirm != true) return;

    final userProvider = context.read<UserProvider>();
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/comments/$commentId'),
        headers: ApiConfig.getHeaders(userProvider.sessionCookie),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        _fetchDetail();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('삭제 권한이 없습니다.')));
      }
    } catch (e) {
      debugPrint('Delete Comment Error: $e');
    }
  }

  Future<void> _updatePostStatus(int newStatusId) async {
    if (_post == null) return;
    setState(() => _isLoading = true);

    final userProvider = context.read<UserProvider>();
    final payload = {
      'boardType': _post!.boardType,
      'title': _post!.title,
      'content': _post!.content,
      'categoryId': _post!.categoryId,
      'priority': _post!.priority,
      'assignedUserId': _post!.assignedUserId,
      'statusId': newStatusId,
    };

    try {
      final res = await http.put(
          Uri.parse('${ApiConfig.baseUrl}/api/posts/${widget.id}'),
          headers: ApiConfig.getHeaders(userProvider.sessionCookie),
          body: jsonEncode(payload));
      if (!mounted) return;
      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('상태가 변경되었습니다.')));
          context.pop(true); // 변경 성공 시 목록으로 나가기 (새로고침 유도)
        }
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('상태 변경에 실패했습니다.')));
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Update Status Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAssigneeDialog() async {
    final userProvider = context.read<UserProvider>();
    final session = userProvider.sessionCookie;

    // 1. 본사 직원 목록 가져오기
    List<Map<String, dynamic>> staffList = [];
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/staff'),
        headers: ApiConfig.getHeaders(session),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as List;
        staffList = data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('Fetch Staff Error: $e');
    }

    if (staffList.isEmpty || !mounted) return;

    // 2. 현재 담당자를 기본 선택값으로
    dynamic selectedUserId = _post?.assignedUserId;
    String selectedName = '';
    // 현재 담당자가 목록에 있으면 이름 매핑
    final current = staffList.where((s) => s['userId'] == selectedUserId).toList();
    if (current.isNotEmpty) {
      selectedName = current.first['name'] ?? '';
    } else {
      selectedUserId = null;
    }

    final searchController = TextEditingController(text: selectedName);
    List<Map<String, dynamic>> filtered = List.from(staffList);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('담당자 지정'),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 선택된 담당자 표시
                    if (selectedUserId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(ctx).colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(ctx).colorScheme.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.userCheck, size: 16, color: Theme.of(ctx).colorScheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '선택됨: $selectedName',
                                style: TextStyle(color: Theme.of(ctx).colorScheme.primary, fontWeight: FontWeight.w600),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setDialogState(() {
                                selectedUserId = null;
                                selectedName = '';
                                searchController.clear();
                                filtered = List.from(staffList);
                              }),
                              child: Icon(LucideIcons.x, size: 16, color: Theme.of(ctx).colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                    // 검색 입력창
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: '이름으로 검색...',
                        prefixIcon: Icon(LucideIcons.search, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          filtered = staffList
                              .where((s) => (s['name'] ?? '').toString().contains(val))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    // 필터링된 직원 목록
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: filtered.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: Text('검색 결과가 없습니다.', style: TextStyle(color: Colors.grey))),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final staff = filtered[i];
                                final isSelected = staff['userId'] == selectedUserId;
                                return ListTile(
                                  dense: true,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  selected: isSelected,
                                  selectedTileColor: Theme.of(ctx).colorScheme.primary.withOpacity(0.08),
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Theme.of(ctx).colorScheme.primary.withOpacity(0.12),
                                    child: Text(
                                      (staff['name'] ?? '?').toString().substring(0, 1),
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(ctx).colorScheme.primary),
                                    ),
                                  ),
                                  title: Text(
                                    staff['name'] ?? '',
                                    style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                                  ),
                                  trailing: isSelected ? Icon(LucideIcons.check, size: 18, color: Theme.of(ctx).colorScheme.primary) : null,
                                  onTap: () {
                                    setDialogState(() {
                                      selectedUserId = staff['userId'];
                                      selectedName = staff['name'] ?? '';
                                      searchController.text = '';
                                      filtered = List.from(staffList);
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('취소'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(64, 36)),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (selectedUserId == null) return;
                    try {
                      final res = await http.patch(
                        Uri.parse('${ApiConfig.baseUrl}/api/posts/${widget.id}/assignee'),
                        headers: ApiConfig.getHeaders(session),
                        body: jsonEncode({'assignedUserId': selectedUserId}),
                      );
                      if (!mounted) return;
                      if (res.statusCode == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('담당자가 변경되었습니다.'), backgroundColor: Colors.green),
                        );
                        context.pop(true); // 변경 성공 시 목록으로 나가기 (새로고침 유도)
                      } else if (mounted) {
                        final msg = jsonDecode(res.body)['message'] ?? '담당자 변경에 실패했습니다.';
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                      }
                    } catch (e) {
                      debugPrint('Update Assignee Error: $e');
                    }
                  },
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusDropdown(int? currentStatus) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: currentStatus == 2
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: currentStatus == 2 ? Colors.green : Colors.orange),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: currentStatus,
          isDense: true,
          icon: Icon(LucideIcons.chevronDown,
              size: 14,
              color: currentStatus == 2 ? Colors.green : Colors.orange),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: currentStatus == 2 ? Colors.green : Colors.orange,
          ),
          items: const [
            DropdownMenuItem(value: 1, child: Text('진행중')),
            DropdownMenuItem(value: 2, child: Text('완료')),
            DropdownMenuItem(value: 3, child: Text('미해결')),
          ],
          onChanged: (val) {
            if (val != null && val != currentStatus) {
              _updatePostStatus(val);
            }
          },
        ),
      ),
    );
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
    final isAuthorOrAdmin =
        currentUser?.role == 1 || currentUser?.userId == post.userId;
    final canChangeStatus = isAuthorOrAdmin ||
        (post.assignedUserId != null &&
            currentUser?.userId == post.assignedUserId);

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
                if (post.boardType == 'ISSUE' &&
                    (currentUser?.role == 1 || currentUser?.companyType == 1))
                  const PopupMenuItem(
                    value: 'assignee',
                    child: Row(
                      children: [
                        Icon(LucideIcons.userCheck, size: 16),
                        SizedBox(width: 8),
                        Text('담당자 지정'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('삭제', style: TextStyle(color: Colors.red))),
              ],
              onSelected: (val) async {
                if (val == 'edit') {
                  final result = await context
                      .push('/edit/${post.boardType}/${post.postId}');
                  if (!mounted) return;
                  if (result == true) {
                    _fetchDetail(); // 수정 성공 시 상세 내용 다시 불러오기
                  }
                } else if (val == 'assignee') {
                  _showAssigneeDialog();
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
          constraints:
              context.isMobile ? null : const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상단 헤더 (제목, 정보)
                      _buildPostHeader(post, canChangeStatus),
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
                      Text('댓글 ${_comments.length}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      ..._comments.map((e) => _buildCommentItem(
                          e, currentUser?.userId, currentUser?.role)),
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

  Widget _buildPostHeader(PostModel post, bool canChangeStatus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (post.boardType == 'ISSUE') ...[
              if (canChangeStatus)
                _buildStatusDropdown(post.statusId)
              else
                _buildBadge(
                    post.statusId == 1
                        ? '진행중'
                        : post.statusId == 2
                            ? '완료'
                            : '미해결',
                    post.statusId == 2 ? Colors.green : Colors.orange),
              const SizedBox(width: 8),
              _buildBadge(
                  post.priority == 4
                      ? '긴급'
                      : post.priority == 3
                          ? '높음'
                          : '보통',
                  post.priority == 4 ? Colors.red : Colors.blue,
                  outlined: true),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(post.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(LucideIcons.user,
                      size: 16, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName ?? '알 수 없음',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(post.authorCompany ?? '',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                    DateFormat('yyyy-MM-dd HH:mm')
                        .format(post.createdAt ?? DateTime.now()),
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text('조회 ${post.viewCount}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  bool _isImageFile(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }

  Future<void> _downloadFile(PostFileModel file) async {
    final encodedOriginName = Uri.encodeComponent(file.originalName);
    final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/files/download/${file.savedName}?originName=$encodedOriginName');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('파일을 열 수 없습니다.')));
      }
    }
  }

  Widget _buildAttachmentList(PostModel post) {
    // 이미지와 일반 파일 분리
    final imageFiles = post.files.where((f) => _isImageFile(f.originalName)).toList();
    final otherFiles = post.files.where((f) => !_isImageFile(f.originalName)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.paperclip, size: 16),
            const SizedBox(width: 6),
            Text('첨부파일 ${post.files.length}개',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 12),

        // 이미지 인라인 미리보기
        if (imageFiles.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: imageFiles.map((file) {
              final displayUrl = '${ApiConfig.baseUrl}/api/files/display/${file.savedName}';
              return GestureDetector(
                onTap: () => _downloadFile(file),
                child: Tooltip(
                  message: '클릭하여 다운로드',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      displayUrl,
                      width: 160,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 160,
                        height: 120,
                        color: Colors.grey[200],
                        child: const Icon(LucideIcons.imageOff, color: Colors.grey),
                      ),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          width: 160,
                          height: 120,
                          color: Colors.grey[100],
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      },
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // 일반 파일 목록
        ...otherFiles.map((file) => Card(
              elevation: 0,
              color: Colors.grey[50],
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[200]!)),
              child: ListTile(
                leading: const Icon(LucideIcons.file, size: 20, color: Colors.blueGrey),
                title: Text(file.originalName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: Text(
                    '${(file.fileSize / 1024).toStringAsFixed(1)} KB',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                trailing: IconButton(
                  icon: const Icon(LucideIcons.download, size: 20, color: Colors.blue),
                  onPressed: () => _downloadFile(file),
                  tooltip: '다운로드',
                ),
              ),
            )),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCommentItem(
      CommentModel comment, int? currentUserId, int? currentUserRole) {
    bool isMyComment = comment.userId == currentUserId || currentUserRole == 1;
    bool isReply = comment.parentId != null && comment.parentId! > 0;

    final key = _commentKeys.putIfAbsent(comment.commentId, () => GlobalKey());

    CommentModel? parentComment;
    if (isReply) {
      try {
        parentComment =
            _comments.firstWhere((c) => c.commentId == comment.parentId);
      } catch (_) {}
    }

    if (comment.isDeleted) {
      return Padding(
        key: key,
        padding: EdgeInsets.only(left: isReply ? 32.0 : 0, bottom: 16.0),
        child: const Text('삭제된 댓글입니다.',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
      );
    }

    return AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        color: _highlightedCommentId == comment.commentId
            ? Colors.yellow.withOpacity(0.2) // 하이라이트 배경색
            : Colors.transparent,
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0), // 하이라이트 영역 확보
        child: Padding(
          key: key,
          padding: EdgeInsets.only(left: isReply ? 32.0 : 8.0, right: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isReply)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0, top: 2.0),
                      child: Icon(LucideIcons.cornerDownRight,
                          size: 16, color: Colors.grey),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('${comment.authorName}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            if (comment.authorRole == 1)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  border: Border.all(color: Colors.red[200]!),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('관리자',
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold)),
                              ),
                            const SizedBox(width: 8),
                            Text(
                                DateFormat('MM-dd HH:mm').format(
                                    comment.createdAt ?? DateTime.now()),
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (isReply &&
                            parentComment != null &&
                            !parentComment.isDeleted)
                          InkWell(
                            onTap: () {
                              _scrollToAndHighlightComment(
                                  parentComment!.commentId);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              margin: const EdgeInsets.only(bottom: 8, top: 4),
                              decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  border: Border(
                                      left: BorderSide(
                                          color: Colors.blue[300]!, width: 4)),
                                  borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(4),
                                      bottomRight: Radius.circular(4))),
                              child: Text(
                                '@${parentComment.authorName}님: ${parentComment.content.replaceAll('\n', ' ')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                            ),
                          ),
                        Text(comment.content,
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  // 대댓글 달기 버튼 (답글)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _replyToCommentId = comment.commentId;
                        _replyToAuthorName = comment.authorName;
                      });
                      _commentController.clear();
                      FocusScope.of(context).requestFocus();
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('답글',
                          style: TextStyle(fontSize: 12, color: Colors.blue)),
                    ),
                  ),
                  // 내 댓글이거나 관리자면 삭제
                  if (isMyComment)
                    InkWell(
                      onTap: () => _deleteComment(comment.commentId),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text('삭제',
                            style: TextStyle(fontSize: 12, color: Colors.red)),
                      ),
                    ),
                ],
              ),
              const Divider(height: 24, thickness: 0.5),
            ],
          ),
        ));
  }

  Widget _buildCommentInputBase() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 8,
          top: 8,
          left: 16,
          right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 답글 타겟 표시
          if (_replyToCommentId != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$_replyToAuthorName님에게 답글 작성 중...',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _replyToCommentId = null;
                        _replyToAuthorName = null;
                      });
                      _commentController.clear();
                    },
                    child:
                        const Icon(LucideIcons.x, size: 14, color: Colors.grey),
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey[100], // 라이트/다크 대응은 Theme에서 알아서
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.blue),
                child: IconButton(
                  icon: const Icon(LucideIcons.send,
                      color: Colors.white, size: 18),
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
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
