import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/core/components/home_app_bar.dart';
import 'package:of_course/core/components/post_component.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/gu_model.dart';
import 'package:of_course/core/models/tags_moedl.dart';

class OfcourseHomePage extends StatefulWidget {
  const OfcourseHomePage({super.key});

  static final ScrollController scrollController = ScrollController();

  @override
  State<OfcourseHomePage> createState() => _OfcourseHomePageState();
}

class _OfcourseHomePageState extends State<OfcourseHomePage> {
  GuModel? selectedGu;
  List<GuModel> guList = [];

  List<TagModel> tagList = [];
  Set<TagModel> selectedCategories = {};

  List<Map<String, dynamic>> courseList = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadGu();
    await _loadTags();
    await _loadCourses();
  }

  Future<void> _loadGu() async {
    final list = await SupabaseManager.shared.getGuList();
    setState(() {
      guList = list;

      selectedGu = null;
    });
  }

  Future<void> _loadTags() async {
    final list = await SupabaseManager.shared.getTags();
    setState(() => tagList = list);
  }

  Future<void> _loadCourses() async {
    final guId = selectedGu?.id;
    final selectedTagNames = selectedCategories.map((t) => t.name).toList();

    final list = await SupabaseManager.shared.getCourseList(
      guId: guId,
      selectedTagNames: selectedTagNames.isEmpty ? null : selectedTagNames,
    );

    setState(() => courseList = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(
        selectedGu: selectedGu,
        guList: guList,
        onGuChanged: (gu) {
          setState(() => selectedGu = gu);
          _loadCourses();
        },
        onNotificationPressed: () => context.push('/alert'),
        selectedCategories: selectedCategories,
      ),

      body: Column(
        children: [
          _buildTagSelector(),
          const SizedBox(height: 12),

          Expanded(
            child: ListView.separated(
              controller: OfcourseHomePage.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: courseList.length,
              itemBuilder: (_, index) {
                final course = courseList[index];

                return PostCard(
                  title: course['title'],
                  tags: (course['tags'] as List).cast<String>(),
                  imageUrls: (course['images'] as List).cast<String>(),
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
                      _loadCourses();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tagList.map((tag) {
            final bool isSelected = selectedCategories.contains(tag);
            return Builder(
              builder: (context) {
                final cs = Theme.of(context).bottomNavigationBarTheme;
                final sc = Theme.of(context).colorScheme;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isSelected
                            ? selectedCategories.remove(tag)
                            : selectedCategories.add(tag);
                      });
                      _loadCourses();
                    },
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
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
