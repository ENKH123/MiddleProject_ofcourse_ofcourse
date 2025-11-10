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

                  RadioGroup<ThemeMode>(
                    groupValue: selected,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selected = value);
                      Navigator.pop(context, value);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<ThemeMode>(
                          value: ThemeMode.system,
                          title: const Text('시스템 모드 따라가기'),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                        ),
                        RadioListTile<ThemeMode>(
                          value: ThemeMode.light,
                          title: const Text('라이트 모드'),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                        ),
                        RadioListTile<ThemeMode>(
                          value: ThemeMode.dark,
                          title: const Text('다크 모드'),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                        ),
                      ],
                    ),
                  ),

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
