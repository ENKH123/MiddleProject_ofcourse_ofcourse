import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:of_course/feature/course/write_and_edit/screens/course_set.dart';
import 'package:of_course/feature/course/write_and_edit/viewmodels/edit_course_view_model.dart';
import 'package:provider/provider.dart';

class EditCoursePage extends StatelessWidget {
  final int courseId;

  const EditCoursePage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditCourseViewModel(courseId: courseId)..init(),
      child: const _EditCourseView(),
    );
  }
}

class _EditCourseView extends StatelessWidget {
  const _EditCourseView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditCourseViewModel>();

    return WillPopScope(
      onWillPop: () => vm.onWillPop(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("코스 수정"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => vm.onWillPop(context),
          ),
          actions: [
            TextButton(
              onPressed: () => vm.onPressSave(context),
              child: const Text("수정완료", style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            controller: vm.scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: vm.titleController,
                  maxLength: 20,
                  decoration: const InputDecoration(hintText: "코스 제목"),
                ),
                const SizedBox(height: 16),

                // MAP
                SizedBox(
                  key: vm.mapKey,
                  height: 300,
                  child: NaverMap(onMapReady: vm.onMapReady),
                ),

                const SizedBox(height: 16),

                // SET LIST
                ...vm.courseSetData.asMap().entries.map((entry) {
                  final i = entry.key;
                  final set = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: WriteCourseSet(
                      key: ValueKey("edit_set_$i"),
                      tagList: vm.tagList,
                      highlight: vm.highlightList[i],
                      existingImageUrls: set.existingImages,
                      initialQuery: set.query,
                      initialDescription: set.description,
                      initialTagId: set.tagId,
                      onTagChanged: (tag) => vm.updateTag(i, tag),
                      onSearchRequested: (q) => vm.onSearch(i, q),
                      onShowMapRequested: () => vm.scrollToMap(),
                      onLocationSaved: (lat, lng) =>
                          vm.onLocationSaved(i, lat, lng),
                      onImagesChanged: (imgs) => vm.updateImages(i, imgs),
                      onExistingImagesChanged: (urls) =>
                          vm.updateExistingImages(i, urls),
                      onDescriptionChanged: (txt) =>
                          vm.updateDescription(i, txt),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Add/Delete set
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: vm.addSet,
                      child: const Text("세트 추가"),
                    ),
                    const SizedBox(width: 12),
                    if (vm.courseSetData.length >= 3)
                      ElevatedButton(
                        onPressed: vm.removeLastSet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        child: const Text("세트 삭제"),
                      ),
                  ],
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
