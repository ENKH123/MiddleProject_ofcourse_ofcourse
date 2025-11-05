import 'package:flutter/material.dart';
import 'package:of_course/components/post_component.dart';

class ViewMyPostPage extends StatelessWidget {
  const ViewMyPostPage({super.key});

  @override
  Widget build(BuildContext context) {
    //더미 데이터
    final List<Map<String, dynamic>> myPosts = List.generate(10, (index) {
      return {
        'title': '내 게시물 제목 $index',
        'tags': ['여행', '맛집', '카페'],
        'images': ['a', 'b', 'c'],
      };
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.black,
                  size: 22,
                ),
              ),

              const Text(
                "내가 작성한 코스",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
      //내가쓴글
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.separated(
            itemCount: myPosts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final post = myPosts[index];
              return PostCard(
                title: post['title'],
                tags: post['tags'],
                imageUrls: ['a', 'b', 'c'],
              );
            },
          ),
        ),
      ),
    );
  }
}
