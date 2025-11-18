import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:of_course/feature/course/write_and_edit/screens/course_set.dart';
import 'package:of_course/feature/course/write_and_edit/viewmodels/write_course_view_model.dart';
import 'package:provider/provider.dart';

class WriteCoursePage extends StatelessWidget {
  final int? continueCourseId;

  const WriteCoursePage({super.key, this.continueCourseId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WriteCourseViewModel()..init(continueCourseId),
      child: const _WriteCourseView(),
    );
  }
}

class _WriteCourseView extends StatelessWidget {
  const _WriteCourseView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WriteCourseViewModel>();

    return WillPopScope(
      onWillPop: vm.handleBackPressed,
      child: Stack(
        children: [
          Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                controller: vm.scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: vm.onTempSave,
                          child: const Text("임시저장"),
                        ),
                        TextButton(
                          onPressed: () => vm.onCancelPressed(context),
                          child: const Text("취소"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 제목
                    TextField(
                      controller: vm.titleController,
                      decoration: InputDecoration(
                        hintText: '코스 제목',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 지도
                    SizedBox(
                      key: vm.mapKey,
                      height: 300,
                      child: NaverMap(
                        onMapReady: vm.onMapReady,
                        options: const NaverMapViewOptions(
                          initialCameraPosition: NCameraPosition(
                            target: NLatLng(37.5665, 126.9780),
                            zoom: 12,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    ...vm.courseSetData.asMap().entries.map((entry) {
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
                          onDescriptionChanged: (txt) =>
                              vm.updateDescription(index, txt),
                          onImagesChanged: (imgs) =>
                              vm.updateImages(index, imgs),
                          onExistingImagesChanged: (list) =>
                              vm.updateExistingImages(index, list),
                          onSearchRequested: (q) => vm.handleSearch(index, q),
                          onLocationSaved: (lat, lng) =>
                              vm.handleLocationSaved(index, lat, lng),
                          onShowMapRequested: vm.scrollToMap,
                        ),
                      );
                    }),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: vm.addSet,
                          child: const Text("세트 추가"),
                        ),
                        const SizedBox(width: 12),
                        if (vm.courseSetData.length > 2)
                          ElevatedButton(
                            onPressed: vm.removeLastSet,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            child: const Text("세트 삭제"),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: vm.onUploadPressed,
                      child: const Text("코스 업로드"),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 🔥 로딩 오버레이
          if (vm.isUploading)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.45),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
