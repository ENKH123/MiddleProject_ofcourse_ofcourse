import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/core/components/post_component.dart';
import 'package:of_course/core/data/core_data_source.dart';
import 'package:of_course/feature/course/liked_course/viewmodel/liked_course_view_model.dart';
import 'package:provider/provider.dart';

class LikedCoursePage extends StatelessWidget {
  const LikedCoursePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LikedCourseViewModel(),
      child: const _LikedCourseView(),
    );
  }
}

class _LikedCourseView extends StatelessWidget {
  const _LikedCourseView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LikedCourseViewModel>();

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
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // 🔥 Tag UI 그대로
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: vm.tagList.map((tag) {
                      final bool isSelected = vm.isSelected(tag);

                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => vm.toggleCategory(tag),
                          child: AnimatedContainer(
                            height: 35,
                            alignment: Alignment.center,
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(
                                      context,
                                    ).bottomNavigationBarTheme.selectedItemColor
                                  : Theme.of(context)
                                        .bottomNavigationBarTheme
                                        .unselectedItemColor,
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
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Colors.black,
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
              ),

              const SizedBox(height: 12),

              // 🔥 Course List 그대로
              Expanded(
                child: vm.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    // 코스가 하나도 없을 때 UI
                    : vm.courseList.isEmpty
                    ? const Center(
                        child: Text(
                          "저장한 코스가 없습니다.",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      )
                    // 코스가 있을 때 기존 리스트 표시
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: vm.courseList.length,
                        itemBuilder: (_, index) {
                          final course = vm.courseList[index];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PostCard(
                              title: course['title'],
                              tags: List<String>.from(course['tags']),
                              imageUrls: List<String>.from(course['images']),
                              likeCount: course['like_count'],
                              commentCount: course['comment_count'],
                              isLiked: course['is_liked'],
                              onTap: () async {
                                final userId = await CoreDataSource.instance
                                    .getMyUserRowId();

                                if (userId == null) return;

                                final updated = await context.push(
                                  '/detail',
                                  extra: {
                                    'courseId': course['id'],
                                    'userId': userId,
                                  },
                                );

                                if (updated == true) {
                                  vm.loadLikedCourses();
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
