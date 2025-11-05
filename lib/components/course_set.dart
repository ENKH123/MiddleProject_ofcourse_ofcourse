import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:of_course/data/enum_data.dart';

class WriteCourseSet extends StatefulWidget {
  const WriteCourseSet({super.key});

  @override
  State<WriteCourseSet> createState() => _WriteCourseSetState();
}

class _WriteCourseSetState extends State<WriteCourseSet> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _images = [];
  final TextEditingController _textController = TextEditingController();
  TagType _selectedTag = TagType.all;

  Future<void> _pickImage() async {
    if (_images.length >= 3) return;
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이미지 선택
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

        const SizedBox(height: 8),

        // 텍스트 입력 (200자)
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

        const SizedBox(height: 8),

        //  태그 선택
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TagType>(
              value: _selectedTag,
              icon: const Icon(Icons.arrow_drop_down),
              isExpanded: true,
              items: TagType.values.map((tag) {
                return DropdownMenuItem<TagType>(
                  value: tag,
                  child: Text(tag.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTag = value;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
