import 'package:flutter/material.dart';
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IntraBoard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // 기기 설정에 따라 다크/라이트 자동 전환
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 웹/데스크탑 환경
          if (constraints.maxWidth > 600) {
            return Center(
              child: Card(
                // theme.dart에서 설정한 CardTheme 적용
                child: Container(
                  width: 450,
                  padding: const EdgeInsets.all(40),
                  child: _buildLoginForm(context),
                ),
              ),
            );
          }
          // 모바일 환경
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Center(child: _buildLoginForm(context)),
          );
        },
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Icon(Icons.dashboard_customize_rounded,
                  size: 48, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'IntraBoard',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Text(
                'B2B Issue Tracking System',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        const Text('아이디', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _idController,
          decoration: const InputDecoration(
            hintText: '아이디를 입력하세요',
          ),
        ),
        const SizedBox(height: 20),
        const Text('비밀번호', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _pwController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: '비밀번호를 입력하세요',
          ),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () {
            // TODO: 로그인 로직 연동
          },
          child: const Text('로그인'),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('처음이신가요?', style: TextStyle(color: Colors.grey)),
            TextButton(
              onPressed: () {},
              child: const Text('회원가입'),
            ),
          ],
        ),
      ],
    );
  }
}
