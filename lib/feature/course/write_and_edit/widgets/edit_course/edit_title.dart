import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/edit_course_view_model.dart';

class EditTitleField extends StatelessWidget {
  const EditTitleField({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditCourseViewModel>();

    return TextField(
      onChanged: (v) => vm.title = v,
      controller: TextEditingController(text: vm.title),
      decoration: const InputDecoration(hintText: "코스 제목"),
    );
  }
}
