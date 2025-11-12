import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OfcourseBottomNavBarUI extends StatelessWidget {
  const OfcourseBottomNavBarUI({super.key});

  int _getIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/write')) return 1;
    if (location.startsWith('/liked')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();
    final index = _getIndex(currentLocation);

    return BottomNavigationBar(
      currentIndex: index,
      onTap: (i) {
        switch (i) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/write');
            break;
          case 2:
            context.go('/liked');
            break;
          case 3:
            context.go('/profile');
            break;
        }
      },
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
