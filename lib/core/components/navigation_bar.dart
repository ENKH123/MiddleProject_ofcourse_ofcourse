import 'package:flutter/material.dart';

class OfcourseBottomNavBarUI extends StatelessWidget {
  const OfcourseBottomNavBarUI({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0, // 기본 선택 인덱스
      onTap: (_) {}, // 아무 기능 없음
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF003366),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.create_outlined),
          activeIcon: Icon(Icons.create),
          label: '코스작성',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark_outline),
          activeIcon: Icon(Icons.bookmark),
          label: '저장한코스',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: '프로필',
        ),
      ],
    );
  }
}
