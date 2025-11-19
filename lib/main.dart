import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:of_course/core/app_theme.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/router/app_router.dart';
import 'package:of_course/feature/alert/providers/alert_provider.dart';
import 'package:of_course/feature/auth/viewmodels/login_viewmodel.dart';
import 'package:of_course/feature/profile/viewmodels/change_profile_viewmodel.dart';
import 'package:of_course/feature/profile/viewmodels/profile_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/providers/auth_provider.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (cert, host, port) => true;
    return client;
  }
}

Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseManager.initialize();
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
  await loadSavedThemeMode();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(),
        ), // 전역 프로바이더 // 로그인 상태 감지
        ChangeNotifierProvider(
          create: (_) => ProfileViewModel(),
        ), // 프로필 ViewModel
        ChangeNotifierProvider(
          create: (_) => ChangeProfileViewModel(),
        ), //프로필변경 viewmodel
        ChangeNotifierProvider(
          create: (_) => AlertProvider(),
        ), // 알림 ViewModel // 알림 감지
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
    final router = createAppRouter(context);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, mode, __) {
        return MaterialApp.router(
          title: 'Of Course',
          debugShowCheckedModeBanner: false,
          themeMode: mode, // 선택된 모드 적용
          theme: lightTheme, //라이트 모드
          darkTheme: darkTheme, //다크 모드
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
