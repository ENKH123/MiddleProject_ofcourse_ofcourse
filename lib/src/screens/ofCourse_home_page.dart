import 'package:flutter/material.dart';
import 'package:of_course/src/components/navigation_bar.dart';
import 'package:of_course/src/components/post_component.dart';
import 'package:of_course/src/data/enum_data.dart';

class OfcourseHomePage extends StatefulWidget {
  const OfcourseHomePage({super.key});

  @override
  State<OfcourseHomePage> createState() => _OfcourseHomePageState();
}

class _OfcourseHomePageState extends State<OfcourseHomePage> {
  SeoulDistrict selectedDistrict = SeoulDistrict.gangnam;
  Set<ToggleButtonType> selectedCategories = {};

  // 더미 데이터
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // 화면 전체 배경색
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Material(
          color: const Color(0xFFFAFAFA), // 앱바 고정 배경색
          elevation: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 지역 드롭다운
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<SeoulDistrict>(
                        value: selectedDistrict,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                        ),
                        onChanged: (value) {
                          setState(() => selectedDistrict = value!);
                        },
                        items: SeoulDistrict.values.map((district) {
                          return DropdownMenuItem(
                            value: district,
                            child: Text(district.displayName),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // random 버튼
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B6B),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'random',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // 알람 버튼
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.black,
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ToggleButtonType.values.map((category) {
                  final bool isSelected = selectedCategories.contains(category);
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedCategories.remove(category);
                          } else {
                            selectedCategories.add(category);
                          }
                        });
                      },
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
                          category.displayName,
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

          // 게시물 리스트
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                itemCount: posts.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return PostCard(
                    title: post['title'],
                    tags: post['tags'],
                    imageUrls: ['images'],
                    likeCount: post['likes'],
                    commentCount: post['comments'],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const OfcourseBottomNavBarUI(),
    );
  }
}
