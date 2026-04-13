import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'theme.dart';
import 'providers/user_provider.dart';
import 'screens/placeholder_screens.dart';
import 'screens/register_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserProvider>();

    _router = GoRouter(
      initialLocation: '/login',
      refreshListenable: userProvider,
      redirect: (context, state) {
        final isLoggedIn = userProvider.isLoggedIn;
        final isLoggingIn = state.matchedLocation == '/login';
        final isRegistering = state.matchedLocation == '/register';

        if (!isLoggedIn && !isLoggingIn && !isRegistering) return '/login';
        if (isLoggedIn && (isLoggingIn || isRegistering)) return '/home';
        return null;
      },
      routes: [
        GoRoute(
            path: '/login', builder: (context, state) => const LoginScreen()),
        GoRoute(
            path: '/register',
            builder: (context, state) => const RegisterScreen()),
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
            path: '/notice',
            builder: (context, state) => const PostListScreen(title: '공지사항')),
        GoRoute(
            path: '/issue',
            builder: (context, state) => const PostListScreen(title: '이슈문의')),
        GoRoute(
            path: '/archive',
            builder: (context, state) => const PostListScreen(title: '자료실')),
        GoRoute(
            path: '/post/:id',
            builder: (context, state) =>
                PostDetailScreen(id: state.pathParameters['id'])),
        GoRoute(
            path: '/write', builder: (context, state) => const WriteScreen()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'IntraBoard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
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
  bool _isObscure = true;

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
          obscureText: _isObscure,
          decoration: InputDecoration(
            hintText: '비밀번호를 입력하세요',
            suffixIcon: IconButton(
              icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _isObscure = !_isObscure),
            ),
          ),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () async {
            final id = _idController.text.trim();
            final pw = _pwController.text.trim();

            if (id.isEmpty || pw.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('아이디와 비밀번호를 입력해주세요.')),
              );
              return;
            }

            // 영문/숫자/특수문자만 허용 검증 (정규식)
            final validPattern = RegExp(r'^[a-zA-Z0-9!@#\$%^&*()_\-+=~`<>]+$');
            if (!validPattern.hasMatch(id) || !validPattern.hasMatch(pw)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('아이디와 비밀번호는 영문, 숫자, 특수문자만 가능합니다.')),
              );
              return;
            }

            final success = await context.read<UserProvider>().login(id, pw);

            if (success) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('로그인 성공!')),
                );
                // TODO: 홈 화면으로 이동
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('로그인 실패. 정보를 확인해주세요.')),
                );
              }
            }
          },
          child: const Text('로그인'),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('처음이신가요?', style: TextStyle(color: Colors.grey)),
            TextButton(
              onPressed: () => context.push('/register'),
              child: const Text('회원가입'),
            ),
          ],
        ),
      ],
    );
  }
}
