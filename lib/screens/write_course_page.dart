import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:of_course/components/course_set.dart';

// --------------------------
// ✅ 전체 페이지
// --------------------------
class WriteCoursePage extends StatefulWidget {
  const WriteCoursePage({super.key});

  @override
  State<WriteCoursePage> createState() => _WriteCoursePageState();
}

class _WriteCoursePageState extends State<WriteCoursePage> {
  final List<Widget> _sets = [const WriteCourseSet(), const WriteCourseSet()];
  File? _mainImage;
  final ImagePicker _picker = ImagePicker();

  void _addSet() {
    setState(() {
      if (_sets.length < 5) _sets.add(const WriteCourseSet());
    });
  }

  void _removeSet() {
    if (_sets.length > 2) {
      setState(() {
        _sets.removeLast();
      });
    }
  }

  Future<void> _pickMainImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _mainImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () {}, child: const Text("임시저장")),
                  TextButton(onPressed: () {}, child: const Text("취소")),
                ],
              ),

              const SizedBox(height: 8),

              // 제목 입력
              TextField(
                decoration: InputDecoration(
                  hintText: '제목을 입력해주세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 페이지 상단 이미지 피커 (200 높이) + X 버튼
              GestureDetector(
                onTap: _pickMainImage,
                child: Stack(
                  children: [
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                        image: _mainImage != null
                            ? DecorationImage(
                                image: FileImage(_mainImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _mainImage == null
                          ? const Center(
                              child: Icon(
                                Icons.add_a_photo,
                                size: 50,
                                color: Colors.grey,
                              ),
                            )
                          : null,
                    ),
                    if (_mainImage != null)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _mainImage = null;
                            });
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 세트 반복 렌더링
              ..._sets.map(
                (set) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: set,
                ),
              ),

              // + / - 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _addSet,
                    icon: const Icon(Icons.add),
                    label: const Text('세트 추가'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_sets.length > 2)
                    ElevatedButton.icon(
                      onPressed: _removeSet,
                      icon: const Icon(Icons.remove),
                      label: const Text('세트 삭제'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 30),

              // ✅ 코스 업로드 버튼 (활성/비활성 예시)
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: 세트마다 내용/태그 체크 후 업로드 로직 구현
                  },
                  child: const Text('코스 업로드'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
