import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:of_course/core/models/tags_moedl.dart';

class WriteCourseSetViewModel extends ChangeNotifier {
  static const _kakaoRestKey = "05df8363e23a77cc74e7c20a667b6c7e";

  // Controllers
  final TextEditingController searchController = TextEditingController();
  final TextEditingController textController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  // Images
  final ImagePicker picker = ImagePicker();
  final List<File> images = [];
  List<String> existingImages = [];

  // Search results
  List<Map<String, dynamic>> searchResults = <Map<String, dynamic>>[];

  // Tags
  TagModel? selectedTag;
  final List<TagModel> tagList;

  WriteCourseSetViewModel({
    required this.tagList,
    String? initialQuery,
    String? initialDescription,
    int? initialTagId,
    List<String>? initialExistingImages,
  }) {
    searchController.text = initialQuery ?? "";
    textController.text = initialDescription ?? "";

    if (initialExistingImages != null) {
      existingImages = List<String>.from(initialExistingImages);
    }

    if (initialTagId != null) {
      try {
        selectedTag = tagList.firstWhere((t) => t.id == initialTagId);
      } catch (_) {}
    }

    textController.addListener(() {
      onDescriptionChanged?.call(textController.text);
    });

    searchFocusNode.addListener(() {
      if (!searchFocusNode.hasFocus) hideSuggestions();
    });
  }

  // Parent callbacks
  Function(String)? onDescriptionChanged;
  Function(List<File>)? onImagesChanged;
  Function(List<String>)? onExistingImagesChanged;
  Function(TagModel)? onTagChanged;
  Function(Map<String, dynamic>)? onSearchSelected;

  // Hide suggestion list
  void hideSuggestions() {
    searchResults = [];
    notifyListeners();
  }

  // Kakao autocomplete
  Future<void> fetchKakaoSuggestions(String query, BuildContext context) async {
    debugPrint("🔎 [자동완성] 입력값: $query");

    if (query.trim().isEmpty) {
      hideSuggestions();
      return;
    }

    try {
      final url = Uri.parse(
        "https://dapi.kakao.com/v2/local/search/keyword.json?query=${Uri.encodeQueryComponent(query)}",
      );

      debugPrint("📡 요청 URL: $url");

      final response = await http.get(
        url,
        headers: {"Authorization": "KakaoAK $_kakaoRestKey"},
      );

      debugPrint("📡 응답 코드: ${response.statusCode}");
      debugPrint("📡 응답 바디: ${response.body}");

      final jsonData = jsonDecode(response.body);
      final docs = jsonData["documents"] ?? [];

      debugPrint("📄 docs.length = ${docs.length}");

      searchResults = docs.map<Map<String, dynamic>>((d) {
        return {
          "name": d["place_name"] ?? "",
          "address": d["road_address_name"] ?? d["address_name"] ?? "",
          "lat": double.tryParse(d["y"] ?? "0") ?? 0,
          "lng": double.tryParse(d["x"] ?? "0") ?? 0,
        };
      }).toList();

      debugPrint("✨ searchResults.length = ${searchResults.length}");

      notifyListeners(); // 자동완성 UI 업데이트
    } catch (e) {
      debugPrint("❌ 자동완성 오류: $e");
    }
  }

  // Manual search
  Future<void> manualSearch(BuildContext context) async {
    final q = searchController.text.trim();
    if (q.isEmpty) return;

    final url = Uri.parse(
      "https://dapi.kakao.com/v2/local/search/keyword.json?query=${Uri.encodeQueryComponent(q)}",
    );

    final response = await http.get(
      url,
      headers: {"Authorization": "KakaoAK $_kakaoRestKey"},
    );

    final docs = jsonDecode(response.body)["documents"];
    if (docs.isEmpty) return;

    final d = docs[0];

    final data = {
      "name": d["place_name"] ?? "",
      "address": d["road_address_name"] ?? d["address_name"] ?? "",
      "lat": double.tryParse(d["y"] ?? "0") ?? 0,
      "lng": double.tryParse(d["x"] ?? "0") ?? 0,
    };

    onSearchSelected?.call(data);
    hideSuggestions();
  }

  Future<File> convertHeicToJpg(File heicFile) async {
    final bytes = await heicFile.readAsBytes();

    // Flutter 자체 HEIC 디코더 없음 → 이미지 라이브러리로 변환
    final decoded = await decodeImageFromList(bytes);

    final picture = await decoded.toByteData(format: ImageByteFormat.png);
    if (picture == null) return heicFile;

    // JPG로 저장
    final jpgBytes = picture.buffer.asUint8List();

    final newPath = heicFile.path.replaceAll(".heic", ".jpg");
    final newFile = File(newPath);
    await newFile.writeAsBytes(jpgBytes);

    return newFile;
  }

  // 이미지 추가 BottomSheet
  Future<void> addImage(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text("사진 촬영"),
                onTap: () async {
                  Navigator.pop(context);
                  final xFile = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (xFile != null) {
                    images.add(File(xFile.path));
                    onImagesChanged?.call(images);
                    notifyListeners();
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.photo),
                title: Text("앨범에서 선택"),
                onTap: () async {
                  Navigator.pop(context);
                  final xFile = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (xFile != null) {
                    File f = File(xFile.path);

                    // HEIC 변환
                    if (f.path.toLowerCase().endsWith(".heic")) {
                      f = await convertHeicToJpg(f);
                    }

                    images.add(f);
                    onImagesChanged?.call(images);
                    notifyListeners();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 이미지 삭제
  void removeLocalImage(int index) {
    images.removeAt(index);
    onImagesChanged?.call(images);
    notifyListeners();
  }

  void removeExistingImage(int index) {
    existingImages.removeAt(index);
    onExistingImagesChanged?.call(existingImages);
    notifyListeners();
  }

  // Tag update
  void updateTag(TagModel tag) {
    selectedTag = tag;
    onTagChanged?.call(tag);
    notifyListeners();
  }
}
