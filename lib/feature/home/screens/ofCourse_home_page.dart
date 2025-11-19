import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/core/components/post_component.dart';
import 'package:of_course/core/data/core_data_source.dart';
import 'package:of_course/feature/home/screens/home_app_bar.dart';
import 'package:of_course/feature/home/viewmodels/ofcourse_home_view_model.dart';
import 'package:provider/provider.dart';

class OfcourseHomePage extends StatelessWidget {
  const OfcourseHomePage({super.key});

  static final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OfcourseHomeViewModel(),
      child: const _OfcourseHomeView(),
    );
  }
}

class _OfcourseHomeView extends StatelessWidget {
  const _OfcourseHomeView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OfcourseHomeViewModel>();

    return WillPopScope(
      onWillPop: () async {
        final shouldExit = vm.handleWillPop();

        if (!shouldExit) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("한 번 더 누르면 앱이 종료됩니다."),
              duration: Duration(seconds: 2),
            ),
          );
        }

        return shouldExit;
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: HomeAppBar(
              selectedGu: vm.selectedGu,
              guList: vm.guList,
              onGuChanged: vm.changeGu,
              onNotificationPressed: () => context.push('/alert'),
              selectedCategories: vm.selectedCategories,
            ),
            body: Column(
              children: [
                _buildTagSelector(context, vm),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    controller: OfcourseHomePage.scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: vm.courseList.length,
                    itemBuilder: (_, index) {
                      final course = vm.courseList[index];

                      return PostCard(
                        title: course['title'],
                        tags: (course['tags'] as List).cast<String>(),
                        imageUrls: (course['images'] as List).cast<String>(),
                        likeCount: course['like_count'],
                        commentCount: course['comment_count'],
                        isLiked: course['is_liked'],
                        onTap: () async {
                          final userId = await CoreDataSource.instance
                              .getMyUserRowId();
                          if (userId == null) return;

                          final updated = await context.push(
                            '/detail',
                            extra: {'courseId': course['id'], 'userId': userId},
                          );

                          if (updated == true) vm.loadCourses();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () async {
                OfcourseHomePage.scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
                await vm.refreshAll();
              },
            ),
          ),

          if (vm.isRefreshing)
            Container(
              color: Colors.black.withOpacity(0.25),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTagSelector(BuildContext context, OfcourseHomeViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: vm.tagList.map((tag) {
            final isSelected = vm.selectedCategories.contains(tag);
            final cs = Theme.of(context).bottomNavigationBarTheme;
            final sc = Theme.of(context).colorScheme;

            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => vm.toggleCategory(tag),
                child: AnimatedContainer(
                  height: 35,
                  alignment: Alignment.center,
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.selectedItemColor
                        : cs.unselectedItemColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    tag.name,
                    style: TextStyle(
                      color: isSelected ? sc.onPrimary : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
