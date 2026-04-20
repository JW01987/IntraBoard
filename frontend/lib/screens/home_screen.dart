import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../config/api_config.dart';
import '../providers/user_provider.dart';
import '../models/post_model.dart';
import '../utils/responsive.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  List<PostModel> _notices = [];
  List<PostModel> _issues = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    final userProvider = context.read<UserProvider>();
    final headers = ApiConfig.getHeaders(userProvider.sessionCookie);

    try {
      // 1. 통계 데이터 호출
      final statsRes = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/admin/dashboard'),
          headers: headers);
      // 2. 최근 공지사항 호출
      final noticeRes = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/posts?boardType=NOTICE&size=5'),
          headers: headers);
      // 3. 최근 이슈 호출
      final issueRes = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/posts?boardType=ISSUE&size=5'),
          headers: headers);

      if (mounted) {
        setState(() {
          if (statsRes.statusCode == 200) {
            _stats = jsonDecode(statsRes.body)['data'];
          }

          if (noticeRes.statusCode == 200) {
            final responseBody = jsonDecode(noticeRes.body);
            final data = responseBody['data'];
            if (data != null && data['list'] != null) {
              final List list = data['list'];
              _notices = list.map((e) => PostModel.fromJson(e)).toList();
            } else {
              _notices = [];
            }
          }

          if (issueRes.statusCode == 200) {
            final responseBody = jsonDecode(issueRes.body);
            final data = responseBody['data'];
            if (data != null && data['list'] != null) {
              final List list = data['list'];
              _issues = list.map((e) => PostModel.fromJson(e)).toList();
            } else {
              _issues = [];
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('안녕하세요, ${user?.name ?? '사용자'}님! 👋',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('오늘의 시스템 현황을 확인하세요.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),

            // 1. 통계 카드 영역
            _buildStatsGrid(),

            const SizedBox(height: 48),

            // 2. 프로젝트/게시글 목록 영역
            context.isMobile
                ? Column(children: [
                    _buildListSection(
                        '최신 공지사항', _notices, () => context.go('/notice')),
                    const SizedBox(height: 32),
                    _buildListSection(
                        '최신 이슈', _issues, () => context.go('/issue'))
                  ])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _buildListSection('최신 공지사항', _notices,
                              () => context.go('/notice'))),
                      const SizedBox(width: 24),
                      Expanded(
                          child: _buildListSection(
                              '최신 이슈', _issues, () => context.go('/issue'))),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {
        'title': '전체 게시글',
        'value': _stats?['totalPosts']?.toString() ?? '0',
        'icon': LucideIcons.fileText,
        'color': Colors.blue
      },
      {
        'title': '진행중 이슈',
        'value': _stats?['inProgressIssues']?.toString() ?? '0',
        'icon': LucideIcons.loader,
        'color': Colors.orange
      },
      {
        'title': '완료된 이슈',
        'value': _stats?['doneIssues']?.toString() ?? '0',
        'icon': LucideIcons.checkCircle,
        'color': Colors.green
      },
      {
        'title': '긴급 이슈',
        'value': _stats?['emergencyIssues']?.toString() ?? '0',
        'icon': LucideIcons.alertCircle,
        'color': Colors.red
      },
    ];

    int crossAxisCount = 4;
    double childAspectRatio = 1.5;

    if (context.width < 600) {
      crossAxisCount = 1;
      childAspectRatio = 2.5; // 카드 높이를 좀 더 확보하여 오버플로우 방지
    } else if (context.width < 1100) {
      crossAxisCount = 2;
      childAspectRatio = 2.0;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        if (_isLoading) return _buildShimmerCard();
        final stat = stats[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(stat['icon'] as IconData,
                    color: stat['color'] as Color, size: 24),
                const SizedBox(height: 12),
                Text(stat['value'] as String,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                Text(stat['title'] as String,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListSection(
      String title, List<PostModel> items, VoidCallback onSeeAll) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(onPressed: onSeeAll, child: const Text('전체보기')),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          ...List.generate(3, (index) => _buildShimmerListTile())
        else if (items.isEmpty)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(32), child: Text('표시할 데이터가 없습니다.')))
        else
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(item.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                      '${item.authorName} • ${item.createdAt?.toString().substring(0, 10) ?? ''}',
                      style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(LucideIcons.chevronRight,
                      size: 16, color: Colors.grey),
                  onTap: () => context.push('/post/${item.postId}'),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(child: Container()),
    );
  }

  Widget _buildShimmerListTile() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListTile(
        title:
            Container(height: 12, width: double.infinity, color: Colors.white),
        subtitle: Container(
            height: 10,
            width: 100,
            color: Colors.white,
            margin: const EdgeInsets.only(top: 8)),
      ),
    );
  }
}
