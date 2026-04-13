import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('앱 종료'),
            content: const Text('앱을 종료하시겠습니까?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('종료')),
            ],
          ),
        );
        if (context.mounted && (shouldExit ?? false)) {
          // 실제 종료 로직은 Platform.exit() 등이 필요하지만 
          // Navigator.pop()은 최상위에서 작동하지 않으므로 보통 뒤로가기 기본동작 수행
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('대시보드')),
        body: const Center(child: Text('홈 화면')),
      ),
    );
  }
}

class PostListScreen extends StatelessWidget {
  final String title;
  const PostListScreen({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('목록 화면')),
    );
  }
}

class PostDetailScreen extends StatelessWidget {
  final String? id;
  const PostDetailScreen({super.key, this.id});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('상세보기')),
      body: Center(child: Text('게시글 상세 ID: $id')),
    );
  }
}

class WriteScreen extends StatelessWidget {
  const WriteScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('글쓰기')),
      body: const Center(child: Text('작성 화면')),
    );
  }
}
