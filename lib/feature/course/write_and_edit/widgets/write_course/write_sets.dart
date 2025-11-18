import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../write_and_edit/screens/course_set.dart';
import '../../../write_and_edit/viewmodels/write_course_view_model.dart';

class WriteSetsList extends StatelessWidget {
  const WriteSetsList({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WriteCourseViewModel>();

    return Column(
      children: [
        ...vm.sets.asMap().entries.map((entry) {
          final index = entry.key;
          final set = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: WriteCourseSet(
              key: ValueKey("write_set_$index"),
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
              onSearchRequested: (q) => vm.updateLocation(index, q),
              onLocationSaved: (lat, lng) => vm.updateLatLng(index, lat, lng),
              onShowMapRequested: () {},
            ),
          );
        }),
      ],
    );
  }
}
