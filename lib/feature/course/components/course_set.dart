import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:of_course/core/models/tags_moedl.dart';

class WriteCourseSet extends StatefulWidget {
  final Function(String query)? onSearchRequested; // 검색 요청 콜백
  final Function(double lat, double lng)? onLocationSaved; // 좌표 저장 콜백

  // ✅ DB 에서 가져온 태그 리스트 전달받기
  final List<TagModel> tagList;
  final Function(TagModel)? onTagChanged; // 선택된 태그 반환 콜백

  const WriteCourseSet({
    super.key,
    required this.tagList,
    this.onTagChanged,
    this.onSearchRequested,
    this.onLocationSaved,
  });

  @override
  State<WriteCourseSet> createState() => _WriteCourseSetState();
}

class _WriteCourseSetState extends State<WriteCourseSet> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _images = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _textController = TextEditingController();

  TagModel? _selectedTag; // ✅ 변경됨

  double? lat;
  double? lng;

  Future<void> _pickImage() async {
    if (_images.length >= 3) return;
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _images.add(File(pickedFile.path)));
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      widget.onSearchRequested?.call(query);
    }
  }

  // 부모에서 위도/경도 전달받을 때 호출
  void updateLocation(double newLat, double newLng) {
    setState(() {
      lat = newLat;
      lng = newLng;
    });
    widget.onLocationSaved?.call(newLat, newLng);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 검색창
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

        const SizedBox(height: 8),

        if (lat != null && lng != null)
          Text(
            '📍 위치 저장됨: ($lat, $lng)',
            style: const TextStyle(color: Colors.green, fontSize: 14),
          ),

        const SizedBox(height: 12),

        // 이미지 선택 영역
        Row(
          children: [
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
            if (_images.length < 3)
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

        const SizedBox(height: 10),

        // 텍스트 입력
        SizedBox(
          height: 150,
          child: TextField(
            controller: _textController,
            maxLength: 200,
            maxLines: null,
            expands: true,
            decoration: InputDecoration(
              hintText: '내용을 입력해주세요 (최대 200자)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
              alignLabelWithHint: true,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ✅ 태그 선택 (DB 기반 드롭다운)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TagModel>(
              value: _selectedTag,
              hint: const Text("태그 선택"),
              isExpanded: true,
              items: widget.tagList.map((tag) {
                return DropdownMenuItem(value: tag, child: Text(tag.name));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedTag = value);
                if (value != null) widget.onTagChanged?.call(value);
              },
            ),
          ),
        ),
      ],
    );
  }
}
