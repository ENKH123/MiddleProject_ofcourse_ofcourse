import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:of_course/core/models/tags_moedl.dart';

class WriteCourseSet extends StatefulWidget {
  final Function(String)? onSearchRequested;
  final Function(double, double)? onLocationSaved;
  final Function(List<File>)? onImagesChanged;
  final Function(List<String>)? onExistingImagesChanged;
  final Function(String)? onDescriptionChanged;
  final Function(TagModel)? onTagChanged;

  final VoidCallback? onShowMapRequested;
  final ValueSetter<double>? onScrollToTop; // ⭐ 검색창 눌렀을 때 부모 스크롤 제어

  final List<TagModel> tagList;
  final bool highlight;

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
    this.onExistingImagesChanged,
    this.onDescriptionChanged,
    this.onShowMapRequested,
    this.onScrollToTop,
    this.highlight = false,
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
  List<Map<String, dynamic>> _searchResults = [];

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _searchFieldKey = GlobalKey(debugLabel: "search_key");
  static const _kakaoRestKey = "05df8363e23a77cc74e7c20a667b6c7e";

  @override
  void initState() {
    super.initState();

    _searchController.text = widget.initialQuery ?? "";
    _textController.text = widget.initialDescription ?? "";

    if (widget.initialTagId != null) {
      try {
        _selectedTag = widget.tagList.firstWhere(
          (t) => t.id == widget.initialTagId,
        );
      } catch (_) {}
    }

    _existingImages = widget.existingImageUrls != null
        ? List<String>.from(widget.existingImageUrls!)
        : [];

    _textController.addListener(() {
      widget.onDescriptionChanged?.call(_textController.text);
    });
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  Future<void> _fetchKakaoSuggestions(String query) async {
    if (query.trim().isEmpty) {
      _removeOverlay();
      return;
    }

    try {
      final url = Uri.parse(
        "https://dapi.kakao.com/v2/local/search/keyword.json?query=${Uri.encodeQueryComponent(query)}",
      );

      final response = await http.get(
        url,
        headers: {"Authorization": "KakaoAK $_kakaoRestKey"},
      );

      final data = jsonDecode(response.body);
      final List docs = data["documents"] ?? [];

      _searchResults = docs.map((d) {
        return {
          "name": d["place_name"],
          "address": d["road_address_name"] ?? d["address_name"],
          "lat": double.parse(d["y"]),
          "lng": double.parse(d["x"]),
        };
      }).toList();

      if (_searchResults.isEmpty) {
        _removeOverlay();
      } else {
        _showOverlay();
      }
    } catch (e) {
      debugPrint("❌ 검색 오류: $e");
    }
  }

  OverlayEntry _createOverlay() {
    return OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: CompositedTransformFollower(
            link: _layerLink,
            offset: const Offset(0, 48), // 검색창 바로 아래
            showWhenUnlinked: false,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _searchResults[index];
                    return ListTile(
                      title: Text(item["name"]),
                      subtitle: Text(item["address"] ?? ""),
                      onTap: () {
                        _removeOverlay();
                        FocusScope.of(context).unfocus();

                        _searchController.text = item["name"];

                        widget.onSearchRequested?.call(item["name"]);
                        widget.onLocationSaved?.call(item["lat"], item["lng"]);

                        widget.onShowMapRequested?.call();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleSearchFieldTap() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox =
          _searchFieldKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final offset = renderBox.localToGlobal(Offset.zero); // 화면 기준 Y좌표
      widget.onScrollToTop?.call(offset.dy);
    });
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlay();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildImageBox(ImageProvider img, VoidCallback onRemove) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(image: img, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black54,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
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
          // --------------------------
          // 검색창 (네이버 지도 스타일)
          // --------------------------
          CompositedTransformTarget(
            link: _layerLink,
            child: Container(
              key: _searchFieldKey,
              child: TextField(
                controller: _searchController,
                onTap: _handleSearchFieldTap, // ⭐ 추가
                onChanged: (v) => _fetchKakaoSuggestions(v),
                decoration: const InputDecoration(hintText: "주소나 매장명 검색"),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // --------------------------
          // 이미지 선택 UI
          // --------------------------
          Row(
            children: [
              for (int i = 0; i < _existingImages.length; i++)
                _buildImageBox(NetworkImage(_existingImages[i]), () {
                  setState(() {
                    _existingImages.removeAt(i);
                  });
                  widget.onExistingImagesChanged?.call(_existingImages);
                }),

              for (int i = 0; i < _images.length; i++)
                _buildImageBox(FileImage(_images[i]), () {
                  setState(() => _images.removeAt(i));
                  widget.onImagesChanged?.call(_images);
                }),

              if (_existingImages.length + _images.length < 3)
                GestureDetector(
                  onTap: () async {
                    final XFile? picked = await _picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (picked != null) {
                      setState(() => _images.add(File(picked.path)));
                      widget.onImagesChanged?.call(_images);
                    }
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // --------------------------
          // 설명
          // --------------------------
          TextField(
            controller: _textController,
            maxLength: 200,
            maxLines: null,
            decoration: const InputDecoration(hintText: "내용을 입력해주세요"),
          ),

          const SizedBox(height: 12),

          // --------------------------
          // 태그 선택
          // --------------------------
          DropdownButtonFormField<TagModel>(
            value: _selectedTag,
            items: widget.tagList
                .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                .toList(),
            onChanged: (v) {
              setState(() => _selectedTag = v);
              widget.onTagChanged?.call(v!);
            },
          ),
        ],
      ),
    );
  }
}
