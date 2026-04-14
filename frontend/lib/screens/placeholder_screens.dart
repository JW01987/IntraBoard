import 'package:flutter/material.dart';

// 실제 구현체(post_list_screen.dart)로 교체됨


class PostDetailScreen extends StatelessWidget {
  final String? id;
  const PostDetailScreen({super.key, this.id});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail')),
      body: Center(child: Text('Post ID: $id')),
    );
  }
}

class WriteScreen extends StatelessWidget {
  const WriteScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Write')),
      body: const Center(child: Text('Write Screen')),
    );
  }
}
