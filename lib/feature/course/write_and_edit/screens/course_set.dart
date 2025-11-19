import 'dart:io';

import 'package:flutter/material.dart';
import 'package:of_course/core/models/tags_moedl.dart';
import 'package:of_course/feature/course/write_and_edit/viewmodels/course_set_view_model.dart';
import 'package:provider/provider.dart';

class WriteCourseSet extends StatelessWidget {
  final List<TagModel> tagList;
  final bool highlight;

  final Function(String)? onSearchRequested;
  final Function(double, double)? onLocationSaved;
  final Function(List<File>)? onImagesChanged;
  final Function(List<String>)? onExistingImagesChanged;
  final Function(String)? onDescriptionChanged;
  final Function(TagModel)? onTagChanged;
  final VoidCallback? onShowMapRequested;

  final String? initialQuery;
  final String? initialDescription;
  final int? initialTagId;
  final List<String>? existingImageUrls;

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
    this.initialQuery,
    this.initialDescription,
    this.initialTagId,
    this.existingImageUrls,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = WriteCourseSetViewModel(
          tagList: tagList,
          initialQuery: initialQuery,
          initialDescription: initialDescription,
          initialExistingImages: existingImageUrls,
          initialTagId: initialTagId,
        );

        vm.onImagesChanged = onImagesChanged;
        vm.onExistingImagesChanged = onExistingImagesChanged;
        vm.onDescriptionChanged = onDescriptionChanged;
        vm.onTagChanged = onTagChanged;

        vm.onSearchSelected = (item) {
          onSearchRequested?.call(item["name"]);
          onLocationSaved?.call(item["lat"], item["lng"]);
          onShowMapRequested?.call();
        };

        return vm;
      },
      child: const _WriteCourseSetView(),
    );
  }
}

class _WriteCourseSetView extends StatelessWidget {
  const _WriteCourseSetView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WriteCourseSetViewModel>();
    final parent = context.findAncestorWidgetOfExactType<WriteCourseSet>()!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: parent.highlight ? Colors.redAccent : Colors.grey.shade300,
          width: parent.highlight ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(context, vm),
              const SizedBox(height: 10),
              _buildImageSection(vm, context),
              const SizedBox(height: 12),
              _buildDescription(vm),
              const SizedBox(height: 12),
              _buildTagDropdown(vm, parent.tagList),
            ],
          ),

          /// 자동완성 리스트는 SearchBar 바로 밑에 위치
          if (vm.searchResults.isNotEmpty) _buildSuggestionList(vm, context),
        ],
      ),
    );
  }

  // 🔍 검색창 (네이버 지도 스타일)
  Widget _buildSearchBar(BuildContext context, WriteCourseSetViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey, size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: vm.searchController,
              focusNode: vm.searchFocusNode,
              onChanged: (v) => vm.fetchKakaoSuggestions(v, context),
              decoration: const InputDecoration(
                hintText: "장소, 매장명 검색",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.grey),
            onPressed: () {
              if (vm.searchController.text.trim().isNotEmpty) {
                vm.manualSearch(context);
              }
            },
          ),
        ],
      ),
    );
  }

  // 🔽 자동완성 리스트
  Widget _buildSuggestionList(
    WriteCourseSetViewModel vm,
    BuildContext context,
  ) {
    return Positioned(
      top: 52,
      left: 0,
      right: 0,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 220),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: vm.searchResults.length,
            itemBuilder: (_, idx) {
              final item = vm.searchResults[idx];
              return ListTile(
                title: Text(item["name"]),
                subtitle: Text(item["address"]),
                onTap: () {
                  vm.searchController.text = item["name"];
                  vm.onSearchSelected?.call(item);
                  vm.hideSuggestions();
                  FocusScope.of(context).unfocus();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // 🖼 이미지 섹션
  Widget _buildImageSection(WriteCourseSetViewModel vm, BuildContext context) {
    final totalCount = vm.existingImages.length + vm.images.length;

    return Row(
      children: [
        for (int i = 0; i < vm.existingImages.length; i++)
          _imageBox(
            image: NetworkImage(vm.existingImages[i]),
            onRemove: () => vm.removeExistingImage(i),
          ),

        for (int i = 0; i < vm.images.length; i++)
          _imageBox(
            image: FileImage(vm.images[i]),
            onRemove: () => vm.removeLocalImage(i),
          ),

        if (totalCount < 3) _addImageButton(() => vm.addImage(context)),
      ],
    );
  }

  Widget _imageBox({
    required ImageProvider image,
    required VoidCallback onRemove,
  }) {
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(image: image, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.black54,
              child: Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addImageButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 90,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: const Center(child: Icon(Icons.add, size: 28)),
      ),
    );
  }

  // ✏ 설명
  Widget _buildDescription(WriteCourseSetViewModel vm) {
    return TextField(
      controller: vm.textController,
      maxLength: 200,
      maxLines: null,
      decoration: const InputDecoration(
        labelText: "해당장소를 추천하는 이유와 장단점을 200자 이하로 작성해주세요",
        border: OutlineInputBorder(),
      ),
    );
  }

  // 🔖 태그 선택
  Widget _buildTagDropdown(WriteCourseSetViewModel vm, List<TagModel> tagList) {
    return DropdownButtonFormField<TagModel>(
      value: vm.selectedTag,
      items: tagList
          .map((t) => DropdownMenuItem<TagModel>(value: t, child: Text(t.name)))
          .toList(),
      decoration: const InputDecoration(
        labelText: "태그 선택",
        border: OutlineInputBorder(),
      ),
      onChanged: (tag) => vm.updateTag(tag!),
    );
  }
}
