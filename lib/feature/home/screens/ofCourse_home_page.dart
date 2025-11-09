import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/core/components/home_app_bar.dart'; // ✅ HomeAppBar 임포트
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
  GuModel? selectedGu;
  List<GuModel> guList = [];

  List<TagModel> tagList = [];
  Set<TagModel> selectedCategories = {};

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
      selectedGu = list.first;
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

      /// ✅ HomeAppBar 적용
      appBar: selectedGu == null
          ? null
          : HomeAppBar(
              selectedGu: selectedGu!,
              guList: guList,
              onGuChanged: (gu) => setState(() => selectedGu = gu),
              onRandomPressed: () {
                // 랜덤 추천 기능 필요 시 여기에 로직
              },
              onNotificationPressed: () {
                context.push('/alert'); // ✅ 화면 이동
              },
              unreadAlertCount: 3, // ✅ 필요하면 count 넣기
            ),

      body: Column(
        children: [
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
                          isSelected
                              ? selectedCategories.remove(tag)
                              : selectedCategories.add(tag);
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
