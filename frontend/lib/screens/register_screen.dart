import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../config/api_config.dart';
import '../models/company_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();
  final _pwConfirmController = TextEditingController();
  final _nameController = TextEditingController();

  List<CompanyModel> _companies = [];
  int? _selectedCompanyId;
  bool _isObscurePw = true;
  bool _isObscureConfirm = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.companiesUrl));
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          final List list = result['data'];
          setState(() {
            _companies = list.map((e) => CompanyModel.fromJson(e)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Fetch Companies Error: $e');
    }
  }

  Future<void> _handleRegister() async {
    final id = _idController.text.trim();
    final pw = _pwController.text.trim();
    final pwConfirm = _pwConfirmController.text.trim();
    final name = _nameController.text.trim();

    // 1. 빈 값 체크
    if (id.isEmpty ||
        pw.isEmpty ||
        name.isEmpty ||
        _selectedCompanyId == null) {
      _showMsg('모든 필드를 입력해주세요.');
      return;
    }

    // 2. 아이디 영문/숫자 검증
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(id)) {
      _showMsg('아이디는 영문과 숫자만 가능합니다.');
      return;
    }

    // 3. 비밀번호 일치 체크
    if (pw != pwConfirm) {
      _showMsg('비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registerUrl),
        headers: ApiConfig.getHeaders(null),
        body: jsonEncode({
          'loginId': id,
          'password': pw,
          'name': name,
          'companyId': _selectedCompanyId,
        }),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success'] == true) {
        if (mounted) {
          _showMsg('회원가입이 완료되었습니다. 로그인해주세요.');
          context.go('/login');
        }
      } else {
        _showMsg(result['message'] ?? '회원가입 실패');
      }
    } catch (e) {
      _showMsg('오류가 발생했습니다: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return Center(
              child: Card(
                child: Container(
                  width: 500,
                  padding: const EdgeInsets.all(40),
                  child: SingleChildScrollView(child: _buildRegisterForm()),
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SingleChildScrollView(child: _buildRegisterForm()),
          );
        },
      ),
    );
  }

  Widget _buildRegisterForm() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(height: 20),
        Text('회원가입',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const Text('IntraBoard 서비스 이용을 위해 가입해주세요.',
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 48),
        _label('아이디'),
        TextField(
          controller: _idController,
          decoration: const InputDecoration(hintText: '영문/숫자 입력'),
        ),
        const SizedBox(height: 20),
        _label('비밀번호'),
        TextField(
          controller: _pwController,
          obscureText: _isObscurePw,
          decoration: InputDecoration(
            hintText: '비밀번호 입력',
            suffixIcon: IconButton(
              icon: Icon(_isObscurePw ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _isObscurePw = !_isObscurePw),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _label('비밀번호 확인'),
        TextField(
          controller: _pwConfirmController,
          obscureText: _isObscureConfirm,
          decoration: InputDecoration(
            hintText: '비밀번호 다시 입력',
            suffixIcon: IconButton(
              icon: Icon(_isObscureConfirm ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _isObscureConfirm = !_isObscureConfirm),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _label('이름'),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(hintText: '실명 입력'),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _label('소속 회사'),
            const SizedBox(width: 4),
            const Tooltip(
              message: '소속회사가 없으면 관리자에게 문의주세요',
              triggerMode: TooltipTriggerMode.tap, // 모바일에서도 탭하면 보이게 설정
              child: Icon(Icons.help_outline, size: 16, color: Colors.grey),
            ),
          ],
        ),
        DropdownButtonFormField<int>(
          value: _selectedCompanyId,
          hint: const Text('회사를 선택하세요'),
          items: _companies.map((c) {
            return DropdownMenuItem(
                value: c.companyId, child: Text(c.companyName));
          }).toList(),
          onChanged: (val) => setState(() => _selectedCompanyId = val),
          decoration: const InputDecoration(),
        ),
        const SizedBox(height: 40),
        FilledButton(
          onPressed: _isLoading ? null : _handleRegister,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('가입하기'),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
