import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'theme.dart';
import 'providers/user_provider.dart';
import 'screens/placeholder_screens.dart';
import 'screens/register_screen.dart';
import 'screens/main_layout.dart';
import 'screens/home_screen.dart';
import 'screens/post_list_screen.dart';
import 'screens/post_detail_screen.dart';
import 'screens/write_screen.dart';
import 'screens/company_management_screen.dart';
import 'screens/user_management_screen.dart';

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
    userProvider.checkAutoLogin(); // 추가된 부분: 앱 진입시 자동로그인 검사 수행

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
        // 인증이 필요한 화면들을 ShellRoute로 그룹화
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            GoRoute(
                path: '/home', builder: (context, state) => const HomeScreen()),
            GoRoute(
                path: '/notice',
                builder: (context, state) =>
                    const PostListScreen(title: '공지사항', boardType: 'NOTICE')),
            GoRoute(
                path: '/issue',
                builder: (context, state) =>
                    PostListScreen(
                      title: '이슈문의',
                      boardType: 'ISSUE',
                      assignedToMe: state.uri.queryParameters['assignedToMe'] == 'true',
                    )),
            GoRoute(
                path: '/archive',
                builder: (context, state) =>
                    const PostListScreen(title: '자료실', boardType: 'ARCHIVE')),
            GoRoute(
                path: '/faq',
                builder: (context, state) =>
                    const PostListScreen(title: 'FAQ', boardType: 'FAQ')),
            GoRoute(
                path: '/companies',
                builder: (context, state) =>
                    const CompanyManagementScreen()),
            GoRoute(
                path: '/admin/users',
                builder: (context, state) =>
                    const UserManagementScreen()),
            GoRoute(
                path: '/post/:id',
                builder: (context, state) =>
                    PostDetailScreen(id: state.pathParameters['id'])),
            GoRoute(
                path: '/write/:boardType',
                builder: (context, state) => WriteScreen(
                      boardType: state.pathParameters['boardType'] ?? 'NOTICE',
                    )),
            GoRoute(
                path: '/edit/:boardType/:id',
                builder: (context, state) => WriteScreen(
                      boardType: state.pathParameters['boardType'] ?? 'NOTICE',
                      postId: state.pathParameters['id'],
                    )),
          ],
        ),
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
  bool _autoLogin = false; // 추가된 부분

  @override
  Widget build(BuildContext context) {
    if (!context.watch<UserProvider>().isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return Center(
              child: Card(
                child: Container(
                  width: 450,
                  padding: const EdgeInsets.all(40),
                  child: _buildLoginForm(context),
                ),
              ),
            );
          }
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
              Icon(LucideIcons.layoutDashboard,
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
          inputFormatters: [
            FilteringTextInputFormatter.allow(
                RegExp(r'[a-zA-Z0-9!@#\$%^&*()_\-+=~`<>]')),
          ],
          decoration: InputDecoration(
            hintText: '비밀번호를 입력하세요',
            suffixIcon: IconButton(
              icon: Icon(_isObscure ? LucideIcons.eyeOff : LucideIcons.eye),
              onPressed: () => setState(() => _isObscure = !_isObscure),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: _autoLogin,
              onChanged: (val) => setState(() => _autoLogin = val ?? false),
            ),
            const Text('자동 로그인', style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () async {
              final id = _idController.text.trim();
              final pw = _pwController.text.trim();

              if (id.isEmpty || pw.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('아이디와 비밀번호를 모두 입력해주세요.')),
                );
                return;
              }

              final validPattern =
                  RegExp(r'^[a-zA-Z0-9!@#\$%^&*()_\-+=~`<>]+$');
              if (!validPattern.hasMatch(id) || !validPattern.hasMatch(pw)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('아이디와 비밀번호는 영문, 숫자, 특수문자만 가능합니다.')),
                );
                return;
              }

              // autoLogin 값을 같이 넘겨준다
              final result = await context.read<UserProvider>().login(id, pw, saveCredentials: _autoLogin);
              if (!mounted) return;
              if (result['success'] != true) {
                final message = result['message'] as String;
                Color bgColor = Colors.red; // 기본 에러 색상
                if (message.contains('승인 대기')) {
                  bgColor = Colors.orange;
                } else if (message.contains('가입이 거절')) {
                  bgColor = Colors.red;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: bgColor,
                    behavior: SnackBarBehavior.floating, // 좀 더 예쁘게
                  ),
                );
              }
            },
            child: const Text('로그인'),
          ),
        ),
        const SizedBox(height: 24),
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
