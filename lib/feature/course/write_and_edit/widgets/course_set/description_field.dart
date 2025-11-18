import 'package:flutter/material.dart';
import 'package:of_course/feature/course/write_and_edit/viewmodels/course_set_view_model.dart';

class DescriptionField extends StatelessWidget {
  final WriteCourseSetViewModel vm;

  const DescriptionField({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: vm.textController,
      maxLength: 200,
      maxLines: null,
      decoration: const InputDecoration(
        hintText: "내용을 입력해주세요",
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
