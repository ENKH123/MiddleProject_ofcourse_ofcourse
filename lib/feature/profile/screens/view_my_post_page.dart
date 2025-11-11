import 'package:flutter/material.dart';
import 'package:of_course/core/components/post_component.dart';
import 'package:of_course/core/managers/supabase_manager.dart';

class ViewMyPostPage extends StatefulWidget {
  final String userId;
  const ViewMyPostPage({super.key, required this.userId});

  @override
  State<ViewMyPostPage> createState() => _ViewMyPostPageState();
}

class _ViewMyPostPageState extends State<ViewMyPostPage> {
  List<Map<String, dynamic>> myPosts = [];

  @override
  void initState() {
    super.initState();
    _loadMyPosts();
  }

  Future<void> _loadMyPosts() async {
    final result = await SupabaseManager.shared.getMyCourses(widget.userId);
    setState(() => myPosts = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(title: const Text("내가 작성한 코스")),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.separated(
          itemCount: myPosts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final post = myPosts[index];
            return PostCard(
              title: post['title'],
              tags: post['tags'],
              imageUrls: post['images'],
            );
          },
        ),
      ),
    );
  }
}
