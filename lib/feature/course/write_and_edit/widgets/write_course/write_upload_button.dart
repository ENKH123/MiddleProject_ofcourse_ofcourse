import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../write_and_edit/viewmodels/write_course_view_model.dart';

class WriteUploadButton extends StatelessWidget {
  const WriteUploadButton({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WriteCourseViewModel>();

    return ElevatedButton(
      child: const Text("코스 업로드"),
      onPressed: () async {
        if (!vm.validate()) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("모든 세트를 올바르게 작성해주세요.")));
          return;
        }

        bool ok = false;
        final isContinue = vm.continueCourseId != null;

        if (isContinue) {
          ok = await vm.saveContinue(vm.continueCourseId!, true);
        } else {
          ok = await vm.saveNew(true);
        }

        if (ok && context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("코스 업로드 완료")));
          context.go('/home');
        }
      },
    );
  }
}
