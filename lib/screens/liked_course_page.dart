import 'package:flutter/material.dart';
import 'package:of_course/components/navigation_bar.dart';
import 'package:of_course/components/post_component.dart';
import 'package:of_course/data/enum_data.dart';

class LikedCoursePage extends StatefulWidget {
  const LikedCoursePage({super.key});

  @override
  State<LikedCoursePage> createState() => _LikedCoursePageState();
}

class _LikedCoursePageState extends State<LikedCoursePage> {
  Set<TagType> selectedCategories = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: TagType.values.map((category) {
                    final bool isSelected = selectedCategories.contains(
                      category,
                    );

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

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  PostCard(title: '예시 코스1', tags: ['맛집', '데이트']),
                  PostCard(title: '예시 코스2', tags: ['오락', '데이트']),
                  PostCard(title: '예시 코스3', tags: ['산책', '데이트']),
                  PostCard(title: '예시 코스4', tags: ['드라이브', '데이트']),
                  PostCard(title: '예시 코스5', tags: ['영화', '데이트']),
                  PostCard(title: '예시 코스6', tags: ['느좋', '데이트']),
                  PostCard(title: '예시 코스7', tags: ['도서', '데이트']),
                  PostCard(title: '예시 코스8', tags: ['액티비티', '데이트']),
                  PostCard(title: '예시 코스9', tags: ['전시/박물관', '데이트']),
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
