import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchPending(),
      _fetchAll(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchPending() async {
    final session = context.read<UserProvider>().sessionCookie;
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/users/pending'),
        headers: ApiConfig.getHeaders(session),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as List;
        _pendingUsers = data.map((e) => UserModel.fromJson(e)).toList();
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
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as List;
        _allUsers = data.map((e) => UserModel.fromJson(e)).toList();
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
      if (res.statusCode == 200) {
        _fetchData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('승인되었습니다.'), backgroundColor: Colors.green));
        }
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

    if (confirm == true) {
      final session = context.read<UserProvider>().sessionCookie;
      try {
        final res = await http.put(
          Uri.parse('${ApiConfig.baseUrl}/api/admin/users/${user.userId}/reject'),
          headers: ApiConfig.getHeaders(session),
        );
        if (res.statusCode == 200) {
          _fetchData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('가입이 거절되었습니다.')));
          }
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    }
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
      return const Scaffold(body: Center(child: Text('접근 권한이 없습니다. 관리자 전용 화면입니다.')));
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
            : TabBarView(
                children: [
                  _buildPendingTab(),
                  _buildAllUsersTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingUsers.isEmpty) return const Center(child: Text('대기 중인 회원이 없습니다.'));
    
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
            side: BorderSide(color: Colors.grey[300]!),
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
    if (_allUsers.isEmpty) return const Center(child: Text('회원이 없습니다.'));

    final isMobile = context.isMobile;

    if (isMobile) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _allUsers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final u = _allUsers[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[300]!)),
            child: ListTile(
              title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${u.companyName ?? ''} | ${u.loginId ?? ''}'),
              trailing: _buildStatusBadge(u.status),
            ),
          );
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
          columns: const [
            DataColumn(label: Text('상태', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('이름', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('아이디', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('소속 회사', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('가입일', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('관리', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _allUsers.map((u) {
            return DataRow(cells: [
              DataCell(_buildStatusBadge(u.status)),
              DataCell(Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(u.loginId ?? '-')),
              DataCell(Text(u.companyName ?? '-')),
              DataCell(Text(u.createdAt != null ? DateFormat('yyyy-MM-dd').format(u.createdAt!) : '-')),
              DataCell(u.status == 0 ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(icon: const Icon(LucideIcons.check, size: 16), label: const Text('승인'), onPressed: () => _approveUser(u)),
                  TextButton.icon(icon: const Icon(LucideIcons.x, size: 16, color: Colors.red), label: const Text('거절', style: TextStyle(color: Colors.red)), onPressed: () => _showRejectConfirmDialog(u)),
                ],
              ) : const SizedBox.shrink()),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
