import 'package:flutter/material.dart';
import 'package:of_course/core/components/navigation_bar.dart';
import 'package:of_course/core/components/post_component.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/tags_moedl.dart';

class LikedCoursePage extends StatefulWidget {
  const LikedCoursePage({super.key});

  @override
  State<LikedCoursePage> createState() => _LikedCoursePageState();
}

class _LikedCoursePageState extends State<LikedCoursePage> {
  List<TagModel> tagList = []; // ✅ DB에서 가져온 태그 리스트
  Set<TagModel> selectedCategories = {}; // ✅ 선택된 태그들

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final tags = await SupabaseManager.shared.getTags();
    setState(() {
      tagList = tags;
    });
  }

  bool _isSelected(TagModel tag) => selectedCategories.contains(tag);

  void _toggleCategory(TagModel tag) {
    setState(() {
      if (_isSelected(tag)) {
        selectedCategories.remove(tag);
      } else {
        selectedCategories.add(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            /// ✅ 태그 선택 바
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: tagList.map((tag) {
                    final bool isSelected = _isSelected(tag);

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
                                ? const Color(0xff003366)
                                : Colors.white,
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
                            tag.name, // ✅ DB에서 가져온 태그명
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
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

            /// ✅ 코스 리스트
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  PostCard(title: '예시 코스1', tags: ['맛집', '데이트']),
                  PostCard(title: '예시 코스2', tags: ['오락', '데이트']),
                  PostCard(title: '예시 코스3', tags: ['산책', '데이트']),
                  PostCard(title: '예시 코스4', tags: ['드라이브', '데이트']),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: OfcourseBottomNavBarUI(),
    );
  }
}
