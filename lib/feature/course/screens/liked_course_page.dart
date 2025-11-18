import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/core/components/post_component.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/tags_moedl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LikedCoursePage extends StatefulWidget {
  const LikedCoursePage({super.key});

  @override
  State<LikedCoursePage> createState() => _LikedCoursePageState();
}

class _LikedCoursePageState extends State<LikedCoursePage> {
  List<TagModel> tagList = [];
  Set<TagModel> selectedCategories = {};
  List<Map<String, dynamic>> courseList = [];

  @override
  void initState() {
    super.initState();
    _loadTags();
    _loadLikedCourses();
  }

  Future<void> _loadTags() async {
    final tags = await SupabaseManager.shared.getTags();
    setState(() {
      tagList = tags;
    });
  }

  Future<void> _loadLikedCourses() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint("⚠️ 로그인된 유저 없음");
      return;
    }

    final selectedTagNames = selectedCategories.map((t) => t.name).toList();

    final data = await SupabaseManager.shared.getLikedCourses(
      selectedTagNames: selectedTagNames,
    );

    setState(() {
      courseList = data;
    });
  }

  bool _isSelected(TagModel tag) => selectedCategories.contains(tag);

  void _toggleCategory(TagModel tag) {
    setState(() {
      _isSelected(tag)
          ? selectedCategories.remove(tag)
          : selectedCategories.add(tag);
    });

    _loadLikedCourses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: tagList.map((tag) {
                    final bool isSelected = _isSelected(tag);

                    return Builder(
                      builder: (context) {
                        final cs = Theme.of(context).bottomNavigationBarTheme;
                        final sc = Theme.of(context).colorScheme;

                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => _toggleCategory(tag),
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
                                  color: isSelected
                                      ? sc.onPrimary
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: courseList.length,
                itemBuilder: (_, index) {
                  final course = courseList[index];

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
                        final userId = await SupabaseManager.shared
                            .getMyUserRowId();
                        if (userId == null) return;

                        final updated = await context.push(
                          '/detail',
                          extra: {'courseId': course['id'], 'userId': userId},
                        );

                        if (updated == true) {
                          _loadLikedCourses();
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
    );
  }
}
