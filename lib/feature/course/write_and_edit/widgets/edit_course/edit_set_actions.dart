import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/edit_course_view_model.dart';

class EditSetActions extends StatelessWidget {
  const EditSetActions({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditCourseViewModel>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(onPressed: vm.addSet, child: const Text("세트 추가")),
        const SizedBox(width: 12),
        if (vm.sets.length > 1)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              final last = vm.sets.length - 1;
              vm.removeSet(last);
            },
            child: const Text("세트 삭제"),
          ),
      ],
    );
  }
}
