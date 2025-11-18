import 'package:flutter/material.dart';
import 'package:of_course/core/models/tags_moedl.dart';
import 'package:of_course/feature/course/write_and_edit/viewmodels/course_set_view_model.dart';

class TagDropdown extends StatelessWidget {
  final WriteCourseSetViewModel vm;
  final List<TagModel> tagList;

  const TagDropdown({super.key, required this.vm, required this.tagList});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<TagModel>(
      value: vm.selectedTag,
      items: tagList
          .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
          .toList(),
      onChanged: (tag) {
        if (tag != null) vm.changeTag(tag);
      },
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
