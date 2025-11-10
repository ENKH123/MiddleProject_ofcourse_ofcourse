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
