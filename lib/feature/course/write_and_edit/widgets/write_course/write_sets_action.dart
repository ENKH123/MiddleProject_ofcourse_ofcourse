import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../write_and_edit/viewmodels/write_course_view_model.dart';

class WriteSetActions extends StatelessWidget {
  const WriteSetActions({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WriteCourseViewModel>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          child: const Text("세트 추가"),
          onPressed: () => vm.addSet(),
        ),
        const SizedBox(width: 12),
        if (vm.sets.length > 2)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("세트 삭제"),
            onPressed: () => vm.deleteSet(vm.sets.length - 1),
          ),
      ],
    );
  }
}
