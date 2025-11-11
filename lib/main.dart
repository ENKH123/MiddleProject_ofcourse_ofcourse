import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/core/app_theme.dart';
import 'package:of_course/core/components/navigation_bar.dart';
import 'package:of_course/core/viewmodels/auth_provider.dart';
import 'package:of_course/feature/auth/screens/login_screen.dart';
import 'package:of_course/feature/auth/screens/register_screen.dart';
import 'package:of_course/feature/auth/screens/terms_agree_screen.dart';
import 'package:of_course/feature/auth/viewmodels/login_viewmodel.dart';
import 'package:of_course/feature/course/screens/course_detail_screen.dart';
import 'package:of_course/feature/course/screens/edit_course_page.dart';
import 'package:of_course/feature/course/screens/liked_course_page.dart';
import 'package:of_course/feature/course/screens/write_course_page.dart';
import 'package:of_course/feature/home/screens/alert_screen.dart';
import 'package:of_course/feature/home/screens/ofCourse_home_page.dart';
import 'package:of_course/feature/profile/screens/change_profile_screen.dart';
import 'package:of_course/feature/profile/screens/profile_screen.dart';
import 'package:of_course/feature/profile/screens/terms_mypage_screen.dart';
import 'package:of_course/feature/profile/screens/view_my_post_page.dart';
import 'package:of_course/feature/report/screens/report_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dbhecolzljfrmgtdjwie.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRiaGVjb2x6bGpmcm1ndGRqd2llIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwNzc2MTQsImV4cCI6MjA3NzY1MzYxNH0.BsKpELVM0vmihAPd37CDs-fm0sdaVZGeNuBaGlgFOac',
  );
  await FlutterNaverMap().init(
    clientId: 'sr1eyuomlk',
    onAuthFailed: (ex) {
      switch (ex) {
        case NQuotaExceededException(:final message):
          print("사용량 초과 (message: $message)");
          break;
        case NUnauthorizedClientException() ||
            NClientUnspecifiedException() ||
            NAnotherAuthFailedException():
          print("인증 실패: $ex");
          break;
      }
    },
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(),
        ), // 전역 프로바이더 // 로그인 상태 감지
      ],
      child: const MyApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  get courseId => 16;

  get reportTargetType => null;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final GoRouter router = GoRouter(
      initialLocation: '/home',
      /*      initialLocation: authProvider.user != null ? '/home' : '/login',*/
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/alert',
          builder: (context, state) => const AlertScreen(),
        ),
        GoRoute(
          path: '/detail',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            final courseId = int.parse(extra['courseId'].toString());
            final userId = extra['userId'].toString();
            return CourseDetailScreen(courseId: courseId, userId: userId);
          },
        ),
        GoRoute(
          path: '/change_profile',
          builder: (context, state) => ChangeProfileScreen(),
        ),
        GoRoute(
          path: '/report',
          builder: (context, state) => ReportScreen(
            targetId: "",
            reportTargetType: reportTargetType,
          ), // 임시 수정
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
          builder: (context, state) {
            final userId = state.extra as String;
            return ViewMyPostPage(userId: userId);
          },
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
            return Scaffold(
              body: child,
              bottomNavigationBar: const OfcourseBottomNavBarUI(),
            );
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const OfcourseHomePage(),
            ),
            GoRoute(
              path: '/write',
              builder: (context, state) => const WriteCoursePage(),
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

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier, // ★
      builder: (_, mode, __) {
        return MaterialApp.router(
          title: 'Of Course',
          debugShowCheckedModeBanner: false,
          theme: lightTheme, //라이트 모드
          darkTheme: darkTheme, //다크 모드
          themeMode: mode, // 선택된 모드 적용
          routerConfig: router,
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
