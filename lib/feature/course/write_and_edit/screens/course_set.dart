import 'dart:io';

import 'package:flutter/material.dart';
import 'package:of_course/core/models/tags_moedl.dart';
import 'package:of_course/feature/course/write_and_edit/viewmodels/course_set_view_model.dart';
import 'package:of_course/feature/course/write_and_edit/widgets/course_set/description_field.dart';
import 'package:of_course/feature/course/write_and_edit/widgets/course_set/image_picker.dart';
import 'package:of_course/feature/course/write_and_edit/widgets/course_set/search_field.dart';
import 'package:of_course/feature/course/write_and_edit/widgets/course_set/tag_dropdown.dart';
import 'package:provider/provider.dart';

class WriteCourseSet extends StatelessWidget {
  final List<TagModel> tagList;

  final Function(String)? onSearchRequested;
  final Function(double, double)? onLocationSaved;
  final Function(List<File>)? onImagesChanged;
  final Function(List<String>)? onExistingImagesChanged;
  final Function(String)? onDescriptionChanged;
  final Function(TagModel)? onTagChanged;
  final VoidCallback? onShowMapRequested;

  final List<String>? existingImageUrls;
  final String? initialQuery;
  final String? initialDescription;
  final int? initialTagId;

  final bool highlight;

  const WriteCourseSet({
    super.key,
    required this.tagList,
    this.highlight = false,
    this.onSearchRequested,
    this.onLocationSaved,
    this.onImagesChanged,
    this.onExistingImagesChanged,
    this.onDescriptionChanged,
    this.onTagChanged,
    this.onShowMapRequested,
    this.existingImageUrls,
    this.initialQuery,
    this.initialDescription,
    this.initialTagId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WriteCourseSetViewModel()
        ..init(
          tagList: tagList,
          initialExistingImages: existingImageUrls,
          initialQuery: initialQuery,
          initialDescription: initialDescription,
          initialTagId: initialTagId,
          onSearchRequested: onSearchRequested,
          onLocationSaved: onLocationSaved,
          onImagesChanged: onImagesChanged,
          onExistingImagesChanged: onExistingImagesChanged,
          onDescriptionChanged: onDescriptionChanged,
          onTagChanged: onTagChanged,
          onShowMapRequested: onShowMapRequested,
        ),
      child: Consumer<WriteCourseSetViewModel>(
        builder: (context, vm, _) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: highlight ? Colors.redAccent : Colors.grey.shade300,
                width: highlight ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                SearchField(vm: vm),
                const SizedBox(height: 12),
                ImagePickerRow(vm: vm),
                const SizedBox(height: 12),
                DescriptionField(vm: vm),
                const SizedBox(height: 12),
                TagDropdown(vm: vm, tagList: tagList),
              ],
            ),
          );
        },
      ),
    );
  }
}
