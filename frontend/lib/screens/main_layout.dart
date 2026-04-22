import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../providers/user_provider.dart';
import '../utils/responsive.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return _MobileLayout(child: child);
    } else {
      return _WebLayout(child: child);
    }
  }
}

// --- Web/Tablet Layout (Sidebar + Body) ---
class _WebLayout extends StatelessWidget {
  final Widget child;
  const _WebLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final isAdmin = user?.role == 1;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                _buildHeader(context, user?.name, user?.companyName),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                    children: [
                      _menuItem(context, '홈', LucideIcons.layoutDashboard, '/home'),
                      _menuItem(context, '공지사항', LucideIcons.megaphone, '/notice'),
                      _menuItem(context, '이슈/문의', LucideIcons.bug, '/issue'),
                      _menuItem(context, '자료실', LucideIcons.archive, '/archive'),
                      _menuItem(context, 'FAQ', LucideIcons.helpCircle, '/faq'),
                      if (isAdmin) ...[
                        const Divider(height: 40),
                        const Padding(
                          padding: EdgeInsets.only(left: 12, bottom: 8),
                          child: Text('ADMIN',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                        _menuItem(context, '고객사 관리', LucideIcons.building2,
                            '/companies'),
                        _menuItem(context, '시스템 설정', Icons.settings_outlined,
                            '/admin/settings'),
                      ],
                    ],
                  ),
                ),
                _logoutButton(context),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Main Content
          Expanded(child: child),
        ],
      ),
    );
  }
}

// --- Mobile Layout (AppBar + BottomNav + Drawer) ---
class _MobileLayout extends StatelessWidget {
  final Widget child;
  const _MobileLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final isAdmin = user?.role == 1;
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final isSubPage = currentLocation.startsWith('/post/') || currentLocation.startsWith('/write/');

    return Scaffold(
      appBar: isSubPage 
        ? null // 서브페이지(글쓰기, 상세 등)에서는 자식 위젯의 AppBar를 사용하도록 숨김
        : AppBar(
            title: const Text('IntraBoard'),
            centerTitle: false,
          ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(user?.name ?? '사용자',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    Text(user?.companyName ?? '소속 정보 없음',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ),
            ListTile(
                leading: const Icon(LucideIcons.helpCircle),
                title: const Text('FAQ'),
                onTap: () => context.go('/faq')),
            if (isAdmin) ...[
              ListTile(
                  leading: const Icon(LucideIcons.building2),
                  title: const Text('고객사 관리'),
                  onTap: () => context.go('/companies')),
            ],
            const Spacer(),
            _logoutButton(context),
          ],
        ),
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _getSelectedIndex(currentLocation),
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: '홈'),
          BottomNavigationBarItem(
              icon: Icon(LucideIcons.megaphone), label: '공지'),
          BottomNavigationBarItem(
              icon: Icon(LucideIcons.bug), label: '이슈'),
          BottomNavigationBarItem(
              icon: Icon(LucideIcons.archive), label: '자료'),
        ],
      ),
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/notice')) return 1;
    if (location.startsWith('/issue')) return 2;
    if (location.startsWith('/archive')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/notice');
        break;
      case 2:
        context.go('/issue');
        break;
      case 3:
        context.go('/archive');
        break;
    }
  }
}

// --- Common UI Components ---

Widget _buildHeader(BuildContext context, String? name, String? company) {
  return Container(
    padding: const EdgeInsets.all(24),
    alignment: Alignment.centerLeft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(LucideIcons.layoutDashboard,
            size: 32, color: Color(0xFF1A73E8)),
        const SizedBox(height: 16),
        Text(name ?? '사용자님',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(company ?? '소속 정보 없음',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    ),
  );
}

Widget _menuItem(
    BuildContext context, String title, IconData icon, String path) {
  final currentLocation = GoRouterState.of(context).matchedLocation;
  final isSelected = currentLocation == path;
  final colorScheme = Theme.of(context).colorScheme;

  return ListTile(
    leading: Icon(icon, color: isSelected ? colorScheme.primary : Colors.grey),
    title: Text(title,
        style: TextStyle(
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        )),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    selected: isSelected,
    selectedTileColor: colorScheme.primary.withOpacity(0.08),
    onTap: () => context.go(path),
  );
}

Widget _logoutButton(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: ListTile(
      leading: const Icon(LucideIcons.logOut, color: Colors.redAccent),
      title: const Text('로그아웃', style: TextStyle(color: Colors.redAccent)),
      onTap: () async {
        await context.read<UserProvider>().logout();
        if (context.mounted) context.go('/login');
      },
    ),
  );
}
