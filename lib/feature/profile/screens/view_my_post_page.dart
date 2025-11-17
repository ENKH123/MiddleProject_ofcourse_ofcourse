import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      appBar: AppBar(scrolledUnderElevation: 0, title: const Text("내가 작성한 코스")),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.separated(
          itemCount: myPosts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final course = myPosts[index];
            return PostCard(
              title: course['title'],
              tags: course['tags'],
              imageUrls: course['images'],
              onTap: () async {
                final userId = await SupabaseManager.shared.getMyUserRowId();
                if (userId == null) return;

                final updated = await context.push(
                  '/detail',
                  extra: {'courseId': course['id'], 'userId': userId},
                );

                if (updated == true) {
                  _loadMyPosts();
                }
              },
            );
          },
        ),
      ),
    );
  }
}
