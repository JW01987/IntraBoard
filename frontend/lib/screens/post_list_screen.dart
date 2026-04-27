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
import '../utils/responsive.dart';

class PostListScreen extends StatefulWidget {
  final String title;
  final String boardType;
  final bool assignedToMe;

  const PostListScreen({
    super.key,
    required this.title,
    required this.boardType,
    this.assignedToMe = false,
  });

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  bool _isLoading = true;
  List<PostModel> _posts = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;

  // Search Filters
  final TextEditingController _searchController = TextEditingController();
  String _dateFilter = 'ALL';
  int? _statusId;
  late bool _assignedToMe;

  @override
  void initState() {
    super.initState();
    _assignedToMe = widget.assignedToMe;
    _fetchPosts();
  }

  @override
  void didUpdateWidget(PostListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.boardType != widget.boardType) {
      _fetchPosts(page: 1); // 타입 변경 시 초기화
    }
  }

  Future<void> _fetchPosts({int page = 1}) async {
    setState(() => _isLoading = true);
    final userProvider = context.read<UserProvider>();

    // 날짜 계산 (전체/1주/1개월/3개월)
    String startDate = '';
    String endDate = '';
    if (_dateFilter != 'ALL') {
      final now = DateTime.now();
      endDate = DateFormat('yyyy-MM-dd').format(now);
      DateTime start;
      if (_dateFilter == '1W')
        start = now.subtract(const Duration(days: 7));
      else if (_dateFilter == '1M')
        start = DateTime(now.year, now.month - 1, now.day);
      else if (_dateFilter == '3M')
        start = DateTime(now.year, now.month - 3, now.day);
      else
        start = now;
      startDate = DateFormat('yyyy-MM-dd').format(start);
    }

    final queryParams = {
      'boardType': widget.boardType,
      'keyword': _searchController.text,
      'startDate': startDate,
      'endDate': endDate,
      'page': page.toString(),
      'size': '10',
    };

    if (_statusId != null) {
      queryParams['statusId'] = _statusId!.toString();
    }
    
    // 내 담당 이슈 필터
    if (widget.boardType == 'ISSUE' && _assignedToMe) {
      final user = userProvider.user;
      if (user != null && user.userId != null) {
        queryParams['assignedUserId'] = user.userId.toString();
      }
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/posts')
        .replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri,
          headers: ApiConfig.getHeaders(userProvider.sessionCookie));
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final data = responseBody['data'];

        if (data != null && data['list'] != null) {
          final List list = data['list'];
          setState(() {
            _posts = list.map((e) => PostModel.fromJson(e)).toList();
            _currentPage = data['currentPage'] ?? 1;
            _totalPages = data['totalPages'] ?? 1;
            _totalCount = data['totalCount'] ?? 0;
            _isLoading = false;
          });
        } else {
          setState(() {
            _posts = [];
            _currentPage = 1;
            _totalPages = 1;
            _totalCount = 0;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Fetch Posts Error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (widget.boardType == 'FAQ')
                    ? _buildFaqList()
                    : context.isMobile
                        ? _buildCardList()
                        : _buildTableView(),
          ),
          _buildPagination(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/write/${widget.boardType}');
          if (result == true) {
            _searchController.clear();
            _fetchPosts(page: 1); // 새 글이 작성되었으므로 첫 페이지로 갱신
          }
        },
        child: const Icon(LucideIcons.penLine),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // 키워드 검색
          SizedBox(
            width: context.isMobile ? double.infinity : 250,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '검색어 입력...',
                prefixIcon: Icon(LucideIcons.search, size: 18),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
              onSubmitted: (_) => _fetchPosts(page: 1),
            ),
          ),
          // 기간 필터
          DropdownButton<String>(
            value: _dateFilter,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('전체 기간')),
              DropdownMenuItem(value: '1W', child: Text('최근 1주')),
              DropdownMenuItem(value: '1M', child: Text('최근 1개월')),
              DropdownMenuItem(value: '3M', child: Text('최근 3개월')),
            ],
            onChanged: (val) => setState(() => _dateFilter = val!),
          ),
          // 상태 필터 (이슈 게시판 전용)
          if (widget.boardType == 'ISSUE')
            DropdownButton<int?>(
              value: _statusId,
              hint: const Text('상태 전체'),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: null, child: Text('상태 전체')),
                DropdownMenuItem(value: 1, child: Text('진행중')),
                DropdownMenuItem(value: 2, child: Text('완료')),
                DropdownMenuItem(value: 3, child: Text('미해결')),
              ],
              onChanged: (val) => setState(() => _statusId = val),
            ),
          if (widget.boardType == 'ISSUE')
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: _assignedToMe,
                  onChanged: (val) {
                    setState(() => _assignedToMe = val ?? false);
                    _fetchPosts(page: 1);
                  },
                ),
                const Text('내 담당만 보기'),
              ],
            ),
          ElevatedButton.icon(
            onPressed: () => _fetchPosts(page: 1),
            icon: const Icon(LucideIcons.filter, size: 16),
            label: const Text('검색'),
          ),
        ],
      ),
    );
  }

  Widget _buildCardList() {
    if (_posts.isEmpty) return const Center(child: Text('게시글이 없습니다.'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                if (widget.boardType == 'ISSUE')
                  _buildStatusBadge(post.statusId),
                Expanded(
                    child: Text(post.title,
                        style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('${post.authorName} • ${post.authorCompany}'),
                Text(
                    DateFormat('yyyy-MM-dd HH:mm')
                        .format(post.createdAt ?? DateTime.now()),
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            trailing: widget.boardType == 'ISSUE'
                ? _buildPriorityBadge(post.priority)
                : null,
            onTap: () async {
              final result = await context.push('/post/${post.postId}');
              if (result == true) _fetchPosts(page: _currentPage);
            },
          ),
        );
      },
    );
  }

  Widget _buildFaqList() {
    if (_posts.isEmpty) return const Center(child: Text('등록된 FAQ가 없습니다.'));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ExpansionTile(
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text('Q',
                  style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
            title: Text(
              post.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            children: [
              const Divider(height: 1),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(top: 4, right: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('A',
                          style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                    Expanded(
                      child: Html(
                        data: post.content ?? '내용이 없습니다.',
                      ),
                    ),
                  ],
                ),
              ),
              if (post.authorName != null)
                Padding(
                  padding: const EdgeInsets.only(right: 20, bottom: 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '최종 업데이트: ${post.authorName} • ${DateFormat('yyyy-MM-dd').format(post.createdAt ?? DateTime.now())}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableView() {
    if (_posts.isEmpty) return const Center(child: Text('게시글이 없습니다.'));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(60),
          2: FixedColumnWidth(120),
          3: FixedColumnWidth(150),
          4: FixedColumnWidth(120),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          _buildTableHeader(),
          ..._posts.map((post) => _buildTableRow(post)).toList(),
        ],
      ),
    );
  }

  TableRow _buildTableHeader() {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey[100]),
      children: const [
        Padding(
            padding: EdgeInsets.all(12),
            child: Text('번호', style: TextStyle(fontWeight: FontWeight.bold))),
        Padding(
            padding: EdgeInsets.all(12),
            child: Text('제목', style: TextStyle(fontWeight: FontWeight.bold))),
        Padding(
            padding: EdgeInsets.all(12),
            child: Text('작성자', style: TextStyle(fontWeight: FontWeight.bold))),
        Padding(
            padding: EdgeInsets.all(12),
            child: Text('작성일', style: TextStyle(fontWeight: FontWeight.bold))),
        Padding(
            padding: EdgeInsets.all(12),
            child: Text('상태', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    );
  }

  TableRow _buildTableRow(PostModel post) {
    return TableRow(
      children: [
        Padding(
            padding: const EdgeInsets.all(12),
            child: Text(post.postId.toString())),
        Padding(
          padding: const EdgeInsets.all(12),
          child: InkWell(
            onTap: () async {
              final result = await context.push('/post/${post.postId}');
              if (result == true) _fetchPosts(page: _currentPage);
            },
            child: Row(
              children: [
                if (widget.boardType == 'ISSUE')
                  _buildPriorityBadge(post.priority),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(post.title,
                        style: const TextStyle(fontWeight: FontWeight.w500))),
              ],
            ),
          ),
        ),
        Padding(
            padding: const EdgeInsets.all(12),
            child: Text('${post.authorName}\n(${post.authorCompany})',
                style: const TextStyle(fontSize: 13))),
        Padding(
            padding: const EdgeInsets.all(12),
            child: Text(DateFormat('yyyy-MM-dd')
                .format(post.createdAt ?? DateTime.now()))),
        Padding(
          padding: const EdgeInsets.all(12),
          child: widget.boardType == 'ISSUE'
              ? _buildStatusBadge(post.statusId)
              : const Text('-'),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(int? statusId) {
    Color color = Colors.grey;
    String label = '알 수 없음';
    if (statusId == 1) {
      color = Colors.orange;
      label = '진행중';
    } else if (statusId == 2) {
      color = Colors.green;
      label = '완료';
    } else if (statusId == 3) {
      color = Colors.red;
      label = '미해결';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPriorityBadge(int? priority) {
    Color color = Colors.grey;
    String label = '보통';
    if (priority == 4) {
      color = Colors.red;
      label = '긴급';
    } else if (priority == 3) {
      color = Colors.orange;
      label = '높음';
    } else if (priority == 2) {
      color = Colors.blue;
      label = '보통';
    } else if (priority == 1) {
      color = Colors.grey;
      label = '낮음';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
              onPressed: _currentPage > 1
                  ? () => _fetchPosts(page: _currentPage - 1)
                  : null,
              icon: const Icon(LucideIcons.chevronLeft)),
          Text('$_currentPage / $_totalPages',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
              onPressed: _currentPage < _totalPages
                  ? () => _fetchPosts(page: _currentPage + 1)
                  : null,
              icon: const Icon(LucideIcons.chevronRight)),
        ],
      ),
    );
  }
}
