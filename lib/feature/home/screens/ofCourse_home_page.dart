import 'package:flutter/material.dart';
import 'package:of_course/core/components/navigation_bar.dart';
import 'package:of_course/core/components/post_component.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/gu_model.dart';
import 'package:of_course/core/models/tags_moedl.dart';

class OfcourseHomePage extends StatefulWidget {
  const OfcourseHomePage({super.key});

  @override
  State<OfcourseHomePage> createState() => _OfcourseHomePageState();
}

class _OfcourseHomePageState extends State<OfcourseHomePage> {
  GuModel? selectedGu; // ✅ 선택된 지역
  List<GuModel> guList = []; // ✅ DB 지역 목록

  List<TagModel> tagList = []; // ✅ DB 태그 목록
  Set<TagModel> selectedCategories = {}; // ✅ 선택된 태그들

  // 더미 게시물
  final List<Map<String, dynamic>> posts = List.generate(10, (index) {
    return {
      'title': '게시물 제목 $index',
      'tags': ['여행', '맛집', '카페'],
      'images': ['a', 'b', 'c'],
      'likes': index * 2,
      'comments': index,
    };
  });

  @override
  void initState() {
    super.initState();
    _loadGu();
    _loadTags();
  }

  Future<void> _loadGu() async {
    final list = await SupabaseManager.shared.getGuList();
    setState(() {
      guList = list;
      selectedGu = list.first; // ✅ 기본 선택값
    });
  }

  Future<void> _loadTags() async {
    final list = await SupabaseManager.shared.getTags();
    setState(() => tagList = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFAFAFA),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ✅ 지역 드롭다운
            if (selectedGu != null)
              DropdownButtonHideUnderline(
                child: DropdownButton<GuModel>(
                  value: selectedGu,
                  onChanged: (v) => setState(() => selectedGu = v),
                  items: guList.map((gu) {
                    return DropdownMenuItem(value: gu, child: Text(gu.name));
                  }).toList(),
                ),
              ),

            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: const Text("random"),
            ),

            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () {},
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // ✅ 태그 토글 바 (DB 기반)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ).copyWith(top: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tagList.map((tag) {
                  final bool isSelected = selectedCategories.contains(tag);
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedCategories.remove(tag);
                          } else {
                            selectedCategories.add(tag);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        height: 35,
                        alignment: Alignment.center,
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
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
                          tag.name,
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

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: posts.length,
              itemBuilder: (_, index) {
                final post = posts[index];
                return PostCard(
                  title: post['title'],
                  tags: post['tags'],
                  imageUrls: const ['images'],
                  likeCount: post['likes'],
                  commentCount: post['comments'],
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: const OfcourseBottomNavBarUI(),
    );
  }
}
