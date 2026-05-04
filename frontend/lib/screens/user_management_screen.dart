import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../models/company_model.dart';
import '../utils/responsive.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  bool _isLoading = true;
  List<UserModel> _pendingUsers = [];
  List<UserModel> _allUsers = [];
  List<CompanyModel> _companies = [];
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      await Future.wait([
        _fetchPending(),
        _fetchAll(),
        _fetchCompanies(),
      ]);
    } catch (e) {
      debugPrint('Fetch Data Global Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchCompanies() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/system/companies'));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final result = jsonDecode(res.body);
        if (result != null && result['data'] != null) {
          final List data = result['data'];
          _companies = data.map((e) => CompanyModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      debugPrint('Fetch companies error: $e');
    }
  }

  Future<void> _fetchPending() async {
    final session = context.read<UserProvider>().sessionCookie;
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/users/pending'),
        headers: ApiConfig.getHeaders(session),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final result = jsonDecode(res.body);
        if (result != null && result['data'] != null) {
          final List data = result['data'];
          _pendingUsers = data.map((e) => UserModel.fromJson(e)).toList();
        } else {
          _pendingUsers = [];
        }
      }
    } catch (e) {
      debugPrint('Fetch pending error: $e');
    }
  }

  Future<void> _fetchAll() async {
    final session = context.read<UserProvider>().sessionCookie;
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/users/all'),
        headers: ApiConfig.getHeaders(session),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final result = jsonDecode(res.body);
        if (result != null && result['data'] != null) {
          final List data = result['data'];
          _allUsers = data.map((e) => UserModel.fromJson(e)).toList();
        } else {
          _allUsers = [];
        }
      }
    } catch (e) {
      debugPrint('Fetch all error: $e');
    }
  }

  Future<void> _approveUser(UserModel user) async {
    final session = context.read<UserProvider>().sessionCookie;
    try {
      final res = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/users/${user.userId}/approve'),
        headers: ApiConfig.getHeaders(session),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('승인되었습니다.'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    }
  }

  Future<void> _updateUser(dynamic userId, Map<String, dynamic> data) async {
    final session = context.read<UserProvider>().sessionCookie;
    try {
      final res = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/users/$userId'),
        headers: ApiConfig.getHeaders(session),
        body: jsonEncode(data),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('수정되었습니다.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('계정 삭제'),
        content: Text('${user.name} 님의 계정을 완전히 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (!mounted || confirm != true) return;
    
    final session = context.read<UserProvider>().sessionCookie;
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/users/${user.userId}'),
        headers: ApiConfig.getHeaders(session),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    }
  }

  Future<void> _showRejectConfirmDialog(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('가입 거절'),
        content: Text('${user.name} 님의 가입을 거절하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('거절', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (!mounted || confirm != true) return;

    final session = context.read<UserProvider>().sessionCookie;
    try {
      final res = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/users/${user.userId}/reject'),
        headers: ApiConfig.getHeaders(session),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('가입이 거절되었습니다.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    }
  }

  void _showChangeCompanyDialog(UserModel user) {
    if (_companies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('회사 목록을 불러오는 중입니다. 잠시 후 다시 시도해주세요.')));
      return;
    }

    CompanyModel? selectedCompany;
    try {
      selectedCompany = _companies.firstWhere(
        (c) => c.companyId == user.companyId,
        orElse: () => _companies.first,
      );
    } catch (e) {
      selectedCompany = _companies.isNotEmpty ? _companies.first : null;
    }

    if (selectedCompany == null) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${user.name} 소속 변경'),
          content: DropdownButton<CompanyModel>(
            isExpanded: true,
            value: selectedCompany,
            items: _companies.map((c) => DropdownMenuItem(value: c, child: Text(c.companyName))).toList(),
            onChanged: (val) => setDialogState(() => selectedCompany = val),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (selectedCompany != null) {
                  _updateUser(user.userId, {'companyId': selectedCompany!.companyId});
                }
              },
              child: const Text('변경'),
            ),
          ],
        ),
      ),
    );
  }

  List<UserModel> get _filteredUsers {
    if (_searchQuery.isEmpty) return _allUsers;
    return _allUsers.where((u) {
      final query = _searchQuery.toLowerCase();
      final nameMatch = u.name.toLowerCase().contains(query);
      final idMatch = u.loginId?.toLowerCase().contains(query) ?? false;
      final companyMatch = u.companyName?.toLowerCase().contains(query) ?? false;
      return nameMatch || idMatch || companyMatch;
    }).toList();
  }

  Widget _buildStatusBadge(int? status) {
    if (status == 1) return _badge('활성', Colors.green);
    if (status == 2) return _badge('거절됨', Colors.red);
    return _badge('승인 대기', Colors.orange);
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    if (user == null || user.role != 1) {
      return const Scaffold(body: Center(child: Text('접근 권한이 없습니다.')));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('회원 관리'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '승인 대기'),
              Tab(text: '전체 회원'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Material(
                child: TabBarView(
                  children: [
                    _buildPendingTab(),
                    _buildAllUsersTab(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingUsers.isEmpty) {
      return const Center(child: Text('대기 중인 회원이 없습니다.'));
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final u = _pendingUsers[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    _buildStatusBadge(u.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text('아이디: ${u.loginId ?? '-'}', style: const TextStyle(color: Colors.grey)),
                Text('소속: ${u.companyName ?? '소속 없음'}', style: const TextStyle(color: Colors.grey)),
                Text('신청일: ${u.createdAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(u.createdAt!) : '-'}', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => _showRejectConfirmDialog(u),
                      child: const Text('거절'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () => _approveUser(u),
                      child: const Text('승인'),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllUsersTab() {
    final filtered = _filteredUsers;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '이름, 아이디, 회사명으로 검색',
              prefixIcon: const Icon(LucideIcons.search, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        Expanded(
          child: context.isMobile 
            ? _buildMobileList(filtered) 
            : _buildDesktopTable(filtered),
        ),
      ],
    );
  }

  Widget _buildMobileList(List<UserModel> users) {
    if (users.isEmpty) {
      return const Center(child: Text('회원이 없습니다.'));
    }
    
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final u = users[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
          child: ListTile(
            title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${u.companyName ?? ''} | ${u.loginId ?? ''}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusBadge(u.status),
                _buildUserActionMenu(u),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(List<UserModel> users) {
    if (users.isEmpty) {
      return const Center(child: Text('회원이 없습니다.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            columns: const [
              DataColumn(label: Text('상태', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('이름', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('아이디', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('소속 회사', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('가입일', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('관리', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: users.map((u) {
              return DataRow(cells: [
                DataCell(_buildStatusBadge(u.status)),
                DataCell(Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(u.loginId ?? '-')),
                DataCell(Text(u.companyName ?? '-')),
                DataCell(Text(u.createdAt != null ? DateFormat('yyyy-MM-dd').format(u.createdAt!) : '-')),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildUserActionMenu(u),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildUserActionMenu(UserModel u) {
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.moreVertical, size: 20),
      onSelected: (val) {
        if (val == 'company') _showChangeCompanyDialog(u);
        if (val == 'toggle') _updateUser(u.userId, {'status': u.status == 1 ? 2 : 1});
        if (val == 'delete') _deleteUser(u);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'company', child: Text('소속 변경')),
        PopupMenuItem(
          value: 'toggle',
          child: Text(u.status == 1 ? '계정 비활성화' : '계정 활성화'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Text('계정 삭제', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
