import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../providers/user_provider.dart';
import '../models/company_model.dart';
import '../utils/responsive.dart';

class CompanyManagementScreen extends StatefulWidget {
  const CompanyManagementScreen({super.key});

  @override
  State<CompanyManagementScreen> createState() =>
      _CompanyManagementScreenState();
}

class _CompanyManagementScreenState extends State<CompanyManagementScreen> {
  bool _isLoading = true;
  List<CompanyModel> _companies = [];

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    setState(() => _isLoading = true);
    final userProvider = context.read<UserProvider>();
    final headers = ApiConfig.getHeaders(userProvider.sessionCookie);

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/system/companies'),
        headers: headers,
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as List;
        setState(() {
          _companies = data.map((e) => CompanyModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Fetch Companies Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCompanyDialog({CompanyModel? company}) async {
    final nameController =
        TextEditingController(text: company?.companyName ?? '');
    int selectedType = company?.companyType ?? 2; // 기본 고객사

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(company == null ? '신규 회사 등록' : '회사 정보 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '회사명',
                  hintText: '회사명을 입력하세요',
                ),
              ),
              const SizedBox(height: 16),
              const Text('회사 유형',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('본사 (관리담당)')),
                      DropdownMenuItem(value: 2, child: Text('고객사')),
                      DropdownMenuItem(value: 3, child: Text('협력사')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedType = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                final payload = {
                  'companyName': nameController.text.trim(),
                  'companyType': selectedType,
                };

                final headers = ApiConfig.getHeaders(
                    context.read<UserProvider>().sessionCookie);
                http.Response res;

                try {
                  if (company == null) {
                    res = await http.post(
                      Uri.parse('${ApiConfig.baseUrl}/api/system/companies'),
                      headers: headers,
                      body: jsonEncode(payload),
                    );
                  } else {
                    res = await http.put(
                      Uri.parse(
                          '${ApiConfig.baseUrl}/api/system/companies/${company.companyId}'),
                      headers: headers,
                      body: jsonEncode(payload),
                    );
                  }

                  if (!mounted) return;
                  if (res.statusCode == 200) {
                    Navigator.pop(ctx, true);
                  } else {
                    final errData = jsonDecode(res.body);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(errData['message'] ?? '처리 실패')));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(ctx)
                      .showSnackBar(SnackBar(content: Text('서버 통신 오류: $e')));
                }
              },
              child: Text(company == null ? '등록' : '수정'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(80, 48), // 전역 무한대 폭 덮어쓰기
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _fetchCompanies();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(company == null ? '회사가 등록되었습니다.' : '회사 정보가 수정되었습니다.')),
        );
      }
    }
  }

  Future<void> _deleteCompany(CompanyModel company) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회사 삭제'),
        content: Text(
            '${company.companyName} 회사를 삭제하시겠습니까?\n해당 소속으로 등록된 회원이 있으면 삭제할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final headers =
        ApiConfig.getHeaders(context.read<UserProvider>().sessionCookie);
    try {
      final res = await http.delete(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/system/companies/${company.companyId}'),
        headers: headers,
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        _fetchCompanies();
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
        }
      } else {
        final errData = jsonDecode(res.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errData['message'] ?? '삭제 실패')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
      }
    }
  }

  String _getTypeName(int type) {
    if (type == 1) return '본사';
    if (type == 3) return '협력사';
    return '고객사';
  }

  Color _getTypeColor(int type) {
    if (type == 1) return Colors.blue;
    if (type == 3) return Colors.orange;
    return Colors.green;
  }

  Widget _buildTypeBadge(int type) {
    final color = _getTypeColor(type);
    final name = _getTypeName(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(name,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    if (user == null || user.role != 1) {
      return const Scaffold(
        body: Center(child: Text('접근 권한이 없습니다. 관리자 전용 화면입니다.')),
      );
    }

    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '고객사 관리',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      FilledButton.icon(
                        onPressed: () => _showCompanyDialog(),
                        icon: const Icon(LucideIcons.plus, size: 16),
                        label: const Text('신규 회사 등록'),
                        style: FilledButton.styleFrom(
                          minimumSize:
                              const Size(140, 48), // 전역 테마의 infinity 무시
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: isMobile ? _buildMobileList() : _buildDesktopTable(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMobileList() {
    if (_companies.isEmpty) return const Center(child: Text('등록된 회사가 없습니다.'));

    return ListView.separated(
      itemCount: _companies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final c = _companies[index];
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
                    Expanded(
                      child: Text(
                        c.companyName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    _buildTypeBadge(c.companyType),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      c.createdAt != null
                          ? DateFormat('yyyy-MM-dd').format(c.createdAt!)
                          : '-',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.edit2,
                              size: 18, color: Colors.blue),
                          onPressed: () => _showCompanyDialog(company: c),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2,
                              size: 18, color: Colors.red),
                          onPressed: () => _deleteCompany(c),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable() {
    if (_companies.isEmpty) return const Center(child: Text('등록된 회사가 없습니다.'));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
          columns: const [
            DataColumn(
                label:
                    Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label:
                    Text('회사명', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label:
                    Text('유형', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label:
                    Text('등록일', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label:
                    Text('관리', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _companies.map((c) {
            return DataRow(cells: [
              DataCell(Text('${c.companyId}')),
              DataCell(Text(c.companyName,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(_buildTypeBadge(c.companyType)),
              DataCell(Text(c.createdAt != null
                  ? DateFormat('yyyy-MM-dd').format(c.createdAt!)
                  : '-')),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      icon: const Icon(LucideIcons.edit2, size: 16),
                      label: const Text('수정'),
                      onPressed: () => _showCompanyDialog(company: c),
                    ),
                    TextButton.icon(
                      icon: const Icon(LucideIcons.trash2,
                          size: 16, color: Colors.red),
                      label:
                          const Text('삭제', style: TextStyle(color: Colors.red)),
                      onPressed: () => _deleteCompany(c),
                    ),
                  ],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
