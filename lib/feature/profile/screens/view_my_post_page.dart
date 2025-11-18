import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/core/components/post_component.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/feature/profile/viewmodels/view_my_post_view_model.dart';
import 'package:provider/provider.dart';

class ViewMyPostPage extends StatelessWidget {
  final String userId;
  const ViewMyPostPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ViewMyPostViewModel(userId),
      child: const _ViewMyPostView(),
    );
  }
}

class _ViewMyPostView extends StatelessWidget {
  const _ViewMyPostView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ViewMyPostViewModel>();

    return Scaffold(
      appBar: AppBar(scrolledUnderElevation: 0, title: const Text("내가 작성한 코스")),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.separated(
          itemCount: vm.myPosts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final course = vm.myPosts[index];
            return PostCard(
              title: course['title'],
              tags: course['tags'],
              imageUrls: course['images'],
              onTap: () async {
                final myUserId = await SupabaseManager.shared.getMyUserRowId();
                if (myUserId == null) return;

                final updated = await context.push(
                  '/detail',
                  extra: {'courseId': course['id'], 'userId': myUserId},
                );

                if (updated == true) {
                  vm.loadMyPosts();
                }
              },
            );
          },
        ),
      ),
    );
  }
}
