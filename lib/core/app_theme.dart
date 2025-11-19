import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 앱 전역 상태
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

// 저장용 key
const _themeModeKey = 'theme_mode';

//앱 시작할 때 호출해서, 저장된 테마 불러오기
Future<void> loadSavedThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final intValue = prefs.getInt(_themeModeKey);

  if (intValue == null) return;
  if (intValue >= 0 && intValue < ThemeMode.values.length) {
    themeModeNotifier.value = ThemeMode.values[intValue];
  }
}

// 사용자가 테마를 바꿀 때 저장하기
Future<void> saveThemeMode(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_themeModeKey, mode.index);
}

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
                    '테마 설정',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // 라이트
                  radioItem('라이트 모드', ThemeMode.light, () async {
                    setState(() => selected = ThemeMode.light);
                    themeModeNotifier.value = ThemeMode.light;
                    await saveThemeMode(ThemeMode.light);
                    Navigator.of(context).pop(ThemeMode.light);
                  }),

                  // 다크
                  radioItem('다크 모드', ThemeMode.dark, () async {
                    setState(() => selected = ThemeMode.dark);
                    themeModeNotifier.value = ThemeMode.dark;
                    await saveThemeMode(ThemeMode.dark);
                    Navigator.of(context).pop(ThemeMode.dark);
                  }),

                  // 시스템
                  radioItem('시스템 설정 따르기', ThemeMode.system, () async {
                    setState(() => selected = ThemeMode.system);
                    themeModeNotifier.value = ThemeMode.system;
                    await saveThemeMode(ThemeMode.system);
                    Navigator.of(context).pop(ThemeMode.system);
                  }),
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
  fontFamily: 'write',
  useMaterial3: true,
  colorScheme:
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF003366), // 메인 포인트 색
        brightness: Brightness.light,
      ).copyWith(
        surface: const Color(0xFFFAFAFA),
        primary: const Color(0xFF003366),
        onPrimary: const Color(0xFFFAFAFA), // 버튼 텍스트 색
        onSurface: const Color(0xFF030303), // 기본 텍스트 색
        surfaceContainer: const Color(0xFFFAFAFA),
        surfaceBright: const Color(0xFFC5D5E4), // 세트 색상
        surfaceContainerHigh: const Color(0xff003366), // 포인트 vs 흰
        surfaceContainerHighest: const Color(0xffa5a5a5), //회색
      ),

  dialogTheme: const DialogThemeData(
    backgroundColor: const Color(0xFFC5D5E4),
    titleTextStyle: TextStyle(color: const Color(0xFF030303)),
  ),

  scaffoldBackgroundColor: const Color(0xFFFAFAFA),
  canvasColor: const Color(0xFFFAFAFA),

  // surfaceTintColor: Colors.transparent,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFF030303)),
    bodyMedium: TextStyle(color: Color(0xFF030303)),
    titleLarge: TextStyle(
      color: Color(0xFF030303),
      fontWeight: FontWeight.bold,
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF003366), // 버튼 배경
      foregroundColor: const Color(0xFFFAFAFA), // 버튼 글자색
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: const Color(0xFF003366)),
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFAFAFA),
    foregroundColor: Color(0xFF030303),
    elevation: 0,
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xfffafafa),
    selectedItemColor: Color(0xff003366),
    unselectedItemColor: Color(0xffc5c5c5),
  ),

  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF003366),
      foregroundColor: const Color(0xFFFAFAFA),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF003366)),
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
  fontFamily: 'write',
  useMaterial3: true,
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: const Color(0xFFC5D5E4), // 버튼 기본 색
    onPrimary: const Color(0xFF030303), // 버튼 텍스트 색
    secondary: const Color(0xFFC5D5E4),
    onSecondary: const Color(0xFF030303),
    error: Colors.redAccent,
    onError: const Color(0xFFFAFAFA),
    background: const Color(0xFF002245), // 전체 배경색
    onBackground: const Color(0xFFFAFAFA), // 기본 글자색
    surface: const Color(0xFF002245),
    onSurface: const Color(0xFFFAFAFA),
    surfaceContainer: const Color(0xFF516C87), //흰 vs 회색 버튼 색상
    surfaceBright: const Color(0xFF0F3A60), // 세트 및 코스 색상
    surfaceContainerHigh: const Color(0xfffafafa), // 흰 vs 포인트
    surfaceContainerHighest: const Color(0xff9E9E9E), //회색
  ),

  dialogTheme: const DialogThemeData(
    backgroundColor: const Color(0xff003366),
    titleTextStyle: TextStyle(color: const Color(0xfffafafa)),
  ),

  scaffoldBackgroundColor: const Color(0xFF002245),
  canvasColor: const Color(0xFF002245),

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
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: const Color(0xFFC5D5E4)),
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
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFC5D5E4)),
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
