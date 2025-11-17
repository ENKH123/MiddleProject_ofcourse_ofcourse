import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/feature/home/screens/ofCourse_home_page.dart';

class OfcourseBottomNavBarUI extends StatelessWidget {
  final Future<bool> Function(String route)? onNavigateAttempt;

  const OfcourseBottomNavBarUI({super.key, this.onNavigateAttempt});

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
      onTap: (i) async {
        String? route;

        switch (i) {
          case 0:
            if (currentLocation.startsWith('/home')) {
              OfcourseHomePage.scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
              return;
            }
            route = '/home';
            break;

          case 1:
            final now = currentLocation;
            context.push('/write', extra: {'from': now});
            return;

          case 2:
            route = '/liked';
            break;

          case 3:
            route = '/profile';
            break;
        }

        if (route == null) return;

        if (onNavigateAttempt != null) {
          final ok = await onNavigateAttempt!(route);
          if (ok && context.mounted) context.go(route);
        } else {
          context.go(route);
        }
      },
      type: BottomNavigationBarType.fixed,
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
