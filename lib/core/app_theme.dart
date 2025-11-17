import 'package:flutter/material.dart';

// 앱 전역 상태
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

Future<ThemeMode?> showThemeModeDialog(
  BuildContext context, {
  ThemeMode? current,
}) {
  final initial = current ?? themeModeNotifier.value;

  return showDialog<ThemeMode>(
    context: context,
    builder: (context) {
      ThemeMode selected = initial;

      Widget radioItem(String label, ThemeMode value, void Function() onPick) {
        return RadioListTile<ThemeMode>(
          value: value,
          groupValue: selected,
          onChanged: (_) => onPick(),
          title: Text(label),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        );
      }

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  const Text(
                    '테마 변경',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  // 시스템 모드
                  radioItem('시스템 모드 따라가기', ThemeMode.system, () {
                    setState(() => selected = ThemeMode.system);
                    Navigator.pop(context, ThemeMode.system);
                  }),

                  // 라이트 모드
                  radioItem('라이트 모드', ThemeMode.light, () {
                    setState(() => selected = ThemeMode.light);
                    Navigator.pop(context, ThemeMode.light);
                  }),

                  // 다크 모드
                  radioItem('다크 모드', ThemeMode.dark, () {
                    setState(() => selected = ThemeMode.dark);
                    Navigator.pop(context, ThemeMode.dark);
                  }),

                  const SizedBox(height: 4),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

/// 라이트 테마
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme:
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF003366), // 메인 포인트 색
        brightness: Brightness.light,
      ).copyWith(
        surface: const Color(0xFFFAFAFA),
        //background: const Color(0xFFFAFAFA),
        primary: const Color(0xFF003366),
        onPrimary: const Color(0xFFFAFAFA), // 버튼 텍스트 색
        onSurface: const Color(0xFF030303), // 기본 텍스트 색
        surfaceContainer: const Color(0xFFFAFAFA),
      ),

  scaffoldBackgroundColor: const Color(0xFFFAFAFA),
  canvasColor: const Color(0xFFFAFAFA),
  cardColor: const Color(0xFF003366),

  // surfaceTintColor: Colors.transparent,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFF030303)),
    bodyMedium: TextStyle(color: Color(0xFF030303)),
    titleLarge: TextStyle(
      color: Color(0xFF030303),
      //fontWeight: FontWeight.bold,
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF003366), // 버튼 배경
      foregroundColor: const Color(0xFFFAFAFA), // 버튼 글자색
      //textStyle: const TextStyle(fontWeight: FontWeight.bold),
      //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF003366),
      //textStyle: const TextStyle(fontWeight: FontWeight.w500),
    ),
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFAFAFA),
    foregroundColor: Color(0xFF030303),
    elevation: 0,
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xfffafafa),
    selectedItemColor: Color(0xff003366),
    unselectedItemColor: Color(0xffD9D9D9),
  ),

  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF003366),
      foregroundColor: const Color(0xFFFAFAFA),
      //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF003366),
      //side: const BorderSide(color: Color(0xFF003366)),
      //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  iconButtonTheme: const IconButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStatePropertyAll(Color(0xFF003366)),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF003366),
    foregroundColor: Color(0xFFFAFAFA),
  ),
);

/// 다크 테마
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: const Color(0xFFC5D5E4), // 버튼 기본 색
    onPrimary: const Color(0xFF030303), // 버튼 텍스트 색
    secondary: const Color(0xFFC5D5E4),
    onSecondary: const Color(0xFF030303),
    error: Colors.redAccent,
    onError: const Color(0xFFFAFAFA),
    //background: const Color(0xFF003366), // 전체 배경색
    //onBackground: const Color(0xFFFAFAFA), // 기본 글자색
    surface: const Color(0xFF002245),
    onSurface: const Color(0xFFFAFAFA),
    surfaceContainer: const Color(0xFF516C87), //흰 vs 회색 버튼 색상
  ),

  scaffoldBackgroundColor: const Color(0xFF002245),
  canvasColor: const Color(0xFF002245),
  cardColor: const Color(0xFFC5D5E4),

  //surfaceTintColor: Colors.transparent,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFFFAFAFA)),
    bodyMedium: TextStyle(color: Color(0xFFFAFAFA)),
    titleLarge: TextStyle(
      color: Color(0xFFFAFAFA),
      //fontWeight: FontWeight.bold,
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFC5D5E4), // 버튼 배경
      foregroundColor: const Color(0xFF030303), // 버튼 글자색
      //textStyle: const TextStyle(fontWeight: FontWeight.bold),
      //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFFC5D5E4),
      //textStyle: const TextStyle(fontWeight: FontWeight.w500),
    ),
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF002245),
    foregroundColor: Color(0xFFFAFAFA),
    elevation: 0,
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xff002245),
    selectedItemColor: Color(0xfffafafa),
    unselectedItemColor: Color(0xffA5A5A5),
  ),

  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFFC5D5E4),
      foregroundColor: const Color(0xFF030303),
      //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFC5D5E4),
      //side: const BorderSide(color: Color(0xFFC5D5E4)),
      //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  iconButtonTheme: const IconButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStatePropertyAll(Color(0xFFfafafa)),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFC5D5E4),
    foregroundColor: Color(0xFF030303),
  ),
);
