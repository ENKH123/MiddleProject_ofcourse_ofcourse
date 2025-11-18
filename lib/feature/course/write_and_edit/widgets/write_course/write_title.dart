import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../write_and_edit/viewmodels/write_course_view_model.dart';

class WriteTitleField extends StatelessWidget {
  const WriteTitleField({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WriteCourseViewModel>();

    return TextField(
      onChanged: (v) => vm.title = v,
      controller: TextEditingController(text: vm.title),
      decoration: InputDecoration(
        hintText: '코스 제목',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
