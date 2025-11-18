import 'package:flutter/material.dart';
import 'package:of_course/feature/course/write_and_edit/screens/course_set.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/edit_course_view_model.dart';

class EditSetsList extends StatelessWidget {
  const EditSetsList({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditCourseViewModel>();

    return Column(
      children: vm.sets.asMap().entries.map((entry) {
        final index = entry.key;
        final set = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: WriteCourseSet(
            key: ValueKey("edit_set_$index"),
            tagList: vm.tagList,
            highlight: vm.highlightList[index],
            initialQuery: set.query,
            initialDescription: set.description,
            initialTagId: set.tagId,
            existingImageUrls: set.existingImages,
            onTagChanged: (tag) => vm.updateTag(index, tag),
            onDescriptionChanged: (txt) => vm.updateDescription(index, txt),
            onImagesChanged: (imgs) => vm.updateNewImages(index, imgs),
            onExistingImagesChanged: (list) =>
                vm.updateExistingImages(index, list),

            onSearchRequested: (q) async {
              await vm.updateLocation(index, q);
            },
            onLocationSaved: (lat, lng) => vm.updateLatLng(index, lat, lng),
          ),
        );
      }).toList(),
    );
  }
}
