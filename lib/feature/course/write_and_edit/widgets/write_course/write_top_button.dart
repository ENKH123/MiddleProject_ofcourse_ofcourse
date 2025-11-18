import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../write_and_edit/viewmodels/write_course_view_model.dart';

class WriteTopButtons extends StatelessWidget {
  const WriteTopButtons({super.key});

  Future<bool> _confirm(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (_) => AlertDialog(
            title: const Text("임시저장하시겠습니까?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("취소"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("확인"),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WriteCourseViewModel>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          child: const Text("임시저장"),
          onPressed: () async {
            final okDialog = await _confirm(context);
            if (!okDialog) return;

            final isContinue = (vm.continueCourseId != null);
            bool ok = false;

            if (isContinue) {
              ok = await vm.saveContinue(vm.continueCourseId!, false);
            } else {
              ok = await vm.saveNew(false);
            }

            if (!ok) return;

            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("임시 저장 완료")));
            }

            Future.microtask(() {
              if (context.mounted) context.go('/home');
            });
          },
        ),
        TextButton(
          child: const Text("취소"),
          onPressed: () => context.go('/home'),
        ),
      ],
    );
  }
}
