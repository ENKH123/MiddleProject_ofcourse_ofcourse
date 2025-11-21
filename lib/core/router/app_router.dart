// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/core/components/navigation_bar.dart';
import 'package:of_course/core/providers/auth_provider.dart';
import 'package:of_course/feature/alert/screens/alert_screen.dart';
import 'package:of_course/feature/auth/screens/login_screen.dart';
import 'package:of_course/feature/auth/screens/register_screen.dart';
import 'package:of_course/feature/auth/screens/terms_agree_screen.dart';
import 'package:of_course/feature/course/detail/screens/course_detail_screen.dart';
import 'package:of_course/feature/course/liked_course/screens/liked_course_page.dart';
import 'package:of_course/feature/course/screens/course_recommend_screen.dart';
import 'package:of_course/feature/course/screens/recommend_onboarding_screen.dart';
import 'package:of_course/feature/course/write_and_edit/screens/edit_course_page.dart';
import 'package:of_course/feature/course/write_and_edit/screens/write_course_page.dart';
import 'package:of_course/feature/course/write_and_edit/screens/write_entry_page.dart';
import 'package:of_course/feature/home/screens/ofCourse_home_page.dart';
import 'package:of_course/feature/profile/screens/change_profile_screen.dart';
import 'package:of_course/feature/profile/screens/profile_screen.dart';
import 'package:of_course/feature/profile/screens/terms_mypage_screen.dart';
import 'package:of_course/feature/profile/screens/view_my_post_page.dart';
import 'package:of_course/feature/report/screens/report_screen.dart';
import 'package:provider/provider.dart';

get reportTargetType => null;

GoRouter createAppRouter(BuildContext context) {
  final authProvider = context.read<AuthProvider>();

  return GoRouter(
    initialLocation: authProvider.isInitialized ? '/home' : '/login',

    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/alert', builder: (context, state) => const AlertScreen()),

      GoRoute(
        path: '/detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CourseDetailScreen(
            courseId: int.parse(extra['courseId'].toString()),
            userId: extra['userId'].toString(),
            recommendationReason: extra['recommendationReason'] as String?,
          );
        },
      ),

      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const RecommendOnboardingScreen(),
      ),
      GoRoute(
        path: '/recommend',
        builder: (context, state) => const CourseRecommendScreen(),
      ),
      GoRoute(
        path: '/change_profile',
        builder: (context, state) => ChangeProfileScreen(),
      ),

      GoRoute(
        path: '/report',
        builder: (context, state) =>
            ReportScreen(targetId: "", reportTargetType: reportTargetType),
      ),

      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsAgreeScreen(),
      ),
      GoRoute(
        path: '/check_thrms',
        builder: (context, state) => const TermsOfUseScreen(),
      ),

      GoRoute(
        path: '/mypost',
        builder: (context, state) =>
            ViewMyPostPage(userId: state.extra as String),
      ),

      GoRoute(
        path: '/editcourse',
        pageBuilder: (context, state) {
          final courseId = state.extra as int;
          return MaterialPage(
            key: ValueKey("editcourse_$courseId"),
            child: EditCoursePage(courseId: courseId),
          );
        },
      ),

      ShellRoute(
        builder: (context, state, child) {
          Future<bool> handleNavAttempt(String route) async {
            if (!state.uri.toString().startsWith('/write')) return true;

            final ok =
                await showDialog<bool>(
                  context: context,
                  barrierDismissible: true,
                  builder: (ctx) => _exitWriteDialog(ctx),
                ) ??
                false;

            return ok;
          }

          return Scaffold(
            body: child,
            bottomNavigationBar: OfcourseBottomNavBarUI(
              onNavigateAttempt: handleNavAttempt,
            ),
          );
        },

        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const OfcourseHomePage(),
          ),

          GoRoute(
            path: '/write',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return WriteEntryPage(from: extra?['from']);
            },
          ),
          GoRoute(
            path: '/write/new',
            pageBuilder: (context, state) =>
                MaterialPage(key: UniqueKey(), child: WriteCoursePage()),
          ),

          GoRoute(
            path: '/write/continue',
            pageBuilder: (context, state) {
              final id = state.extra as int;
              return MaterialPage(
                key: ValueKey(
                  "write_continue_$id${DateTime.now().millisecondsSinceEpoch}",
                ),
                child: WriteCoursePage(continueCourseId: id),
              );
            },
          ),

          GoRoute(
            path: '/liked',
            builder: (context, state) => const LikedCoursePage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}

Widget _exitWriteDialog(BuildContext ctx) {
  return Center(
    child: Material(
      color: Colors.transparent,
      child: Container(
        width: 290,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 42,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            const Text(
              "코스 작성을 취소하시겠습니까?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              "저장되지 않은 내용이 사라집니다.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(ctx, true),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "확인",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pop(ctx, false),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text("취소"),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
