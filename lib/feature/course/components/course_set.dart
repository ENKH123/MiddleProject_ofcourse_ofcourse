import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:of_course/core/models/tags_moedl.dart';

class WriteCourseSet extends StatefulWidget {
  final Function(String)? onSearchRequested;
  final Function(double, double)? onLocationSaved;
  final Function(List<File>)? onImagesChanged;
  final Function(String)? onDescriptionChanged;
  final Function(TagModel)? onTagChanged;
  final List<TagModel> tagList;
  final bool highlight;
  final VoidCallback? onShowMapRequested;

  final List<String>? existingImageUrls;
  final String? initialQuery;
  final String? initialDescription;
  final int? initialTagId;

  const WriteCourseSet({
    super.key,
    required this.tagList,
    this.onTagChanged,
    this.onSearchRequested,
    this.onLocationSaved,
    this.onImagesChanged,
    this.onDescriptionChanged,
    this.highlight = false,
    this.onShowMapRequested,
    this.existingImageUrls,
    this.initialQuery,
    this.initialDescription,
    this.initialTagId,
  });

  @override
  State<WriteCourseSet> createState() => _WriteCourseSetState();
}

class _WriteCourseSetState extends State<WriteCourseSet> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _images = [];
  late List<String> _existingImages;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  TagModel? _selectedTag;

  @override
  void initState() {
    super.initState();

    _searchController.text = widget.initialQuery ?? "";
    _textController.text = widget.initialDescription ?? "";

    // 태그 초기 선택
    if (widget.initialTagId != null) {
      try {
        _selectedTag = widget.tagList.firstWhere(
          (t) => t.id == widget.initialTagId,
        );
      } catch (_) {
        _selectedTag = null;
      }
    }

    // 이미지 초기값
    _existingImages = widget.existingImageUrls != null
        ? List<String>.from(widget.existingImageUrls!)
        : [];

    // 설명 입력 변경 → 부모에게 전달
    _textController.addListener(() {
      widget.onDescriptionChanged?.call(_textController.text);
    });
  }

  Future<void> _pickImage() async {
    if (_images.length >= 3) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("앨범에서 선택"),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? picked = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (picked != null) {
                    setState(() => _images.add(File(picked.path)));
                    widget.onImagesChanged?.call(_images);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("사진 촬영"),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? picked = await _picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (picked != null) {
                    setState(() => _images.add(File(picked.path)));
                    widget.onImagesChanged?.call(_images);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
    widget.onImagesChanged?.call(_images);
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus(); // ✅ 키보드 내림
    widget.onSearchRequested?.call(query); // ✅ 위치 검색
    widget.onShowMapRequested?.call(); // ✅ 지도 스크롤 요청
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      transform: widget.highlight
          ? Matrix4.translationValues(4, 0, 0)
          : Matrix4.identity(),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: widget.highlight ? Colors.redAccent : Colors.grey.shade300,
          width: widget.highlight ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 검색
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '주소나 매장명 검색',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _onSearch, child: const Text('검색')),
            ],
          ),

          const SizedBox(height: 12),

          // 이미지
          Row(
            children: [
              // 기존 이미지 표시
              for (int i = 0; i < _existingImages.length; i++)
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(_existingImages[i]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _existingImages.removeAt(i));
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black54,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              // 새로 추가한 이미지 표시
              for (int i = 0; i < _images.length; i++)
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(_images[i]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () => _removeImage(i),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black54,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              // 추가 버튼
              if (_existingImages.length + _images.length < 3)
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.grey, size: 30),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // 설명
          TextField(
            controller: _textController,
            maxLength: 200,
            maxLines: null,
            decoration: InputDecoration(
              hintText: '내용을 입력해주세요 (200자 이하)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 태그 선택
          DropdownButtonFormField<TagModel>(
            value: _selectedTag,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: "태그 선택",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: widget.tagList.map((tag) {
              return DropdownMenuItem(value: tag, child: Text(tag.name));
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedTag = value);
              if (value != null) widget.onTagChanged?.call(value);
            },
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
