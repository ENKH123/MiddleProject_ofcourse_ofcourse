import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:of_course/core/models/tags_moedl.dart';

class WriteCourseSetViewModel extends ChangeNotifier {
  static const _kakaoRestKey = "05df8363e23a77cc74e7c20a667b6c7e";
  final ImagePicker _picker = ImagePicker();

  // ------------------------------
  // Data
  // ------------------------------
  final TextEditingController searchController = TextEditingController();
  final TextEditingController textController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  final List<File> images = [];
  List<String> existingImages = [];
  TagModel? selectedTag;

  List<Map<String, dynamic>> searchResults = [];

  OverlayEntry? overlayEntry;
  final LayerLink layerLink = LayerLink();

  // Callbacks from parent
  Function(String)? onSearchRequested;
  Function(double, double)? onLocationSaved;
  Function(List<File>)? onImagesChanged;
  Function(List<String>)? onExistingImagesChanged;
  Function(String)? onDescriptionChanged;
  Function(TagModel)? onTagChanged;
  VoidCallback? onShowMapRequested;

  // ------------------------------
  // Init
  // ------------------------------
  void init({
    required List<String>? initialExistingImages,
    required String? initialQuery,
    required String? initialDescription,
    required int? initialTagId,
    required List<TagModel> tagList,
    required Function(String)? onSearchRequested,
    required Function(double, double)? onLocationSaved,
    required Function(List<File>)? onImagesChanged,
    required Function(List<String>)? onExistingImagesChanged,
    required Function(String)? onDescriptionChanged,
    required Function(TagModel)? onTagChanged,
    required VoidCallback? onShowMapRequested,
  }) {
    this.onSearchRequested = onSearchRequested;
    this.onLocationSaved = onLocationSaved;
    this.onImagesChanged = onImagesChanged;
    this.onExistingImagesChanged = onExistingImagesChanged;
    this.onDescriptionChanged = onDescriptionChanged;
    this.onTagChanged = onTagChanged;
    this.onShowMapRequested = onShowMapRequested;

    existingImages = initialExistingImages ?? [];
    searchController.text = initialQuery ?? "";
    textController.text = initialDescription ?? "";

    if (initialTagId != null) {
      selectedTag = tagList.firstWhere(
        (t) => t.id == initialTagId,
        orElse: () => tagList.first,
      );
    }

    textController.addListener(() {
      onDescriptionChanged?.call(textController.text);
    });

    notifyListeners();
  }

  // ------------------------------
  // Search API
  // ------------------------------
  Future<void> fetchKakaoSuggestions(String query) async {
    if (query.trim().isEmpty) {
      searchResults = [];
      hideOverlay();
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

      searchResults = docs.map((d) {
        return {
          "name": d["place_name"],
          "address": d["road_address_name"] ?? d["address_name"],
          "lat": double.parse(d["y"]),
          "lng": double.parse(d["x"]),
        };
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint("❌ 검색 오류: $e");
    }
  }

  // ------------------------------
  // Overlay
  // ------------------------------
  void showOverlay(BuildContext context, Widget overlayWidget) {
    hideOverlay();
    overlayEntry = OverlayEntry(builder: (_) => overlayWidget);
    Overlay.of(context).insert(overlayEntry!);
  }

  void hideOverlay() {
    overlayEntry?.remove();
    overlayEntry = null;
  }

  // ------------------------------
  // Manual Search
  // ------------------------------
  Future<void> manualSearch() async {
    final query = searchController.text.trim();
    if (query.isEmpty) return;

    try {
      final url = Uri.parse(
        "https://dapi.kakao.com/v2/local/search/keyword.json?query=${Uri.encodeQueryComponent(query)}",
      );

      final response = await http.get(
        url,
        headers: {"Authorization": "KakaoAK $_kakaoRestKey"},
      );

      final data = jsonDecode(response.body);
      final docs = data["documents"] ?? [];

      if (docs.isEmpty) return;

      final item = docs.first;

      onSearchRequested?.call(query);
      onLocationSaved?.call(double.parse(item["y"]), double.parse(item["x"]));

      onShowMapRequested?.call();
      hideOverlay();
    } catch (e) {
      debugPrint("❌ 직접 검색 실패: $e");
    }
  }

  // ------------------------------
  // Image Actions
  // ------------------------------
  Future<void> pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      images.add(File(picked.path));
      onImagesChanged?.call(images);
      notifyListeners();
    }
  }

  void removeNewImage(int index) {
    images.removeAt(index);
    onImagesChanged?.call(images);
    notifyListeners();
  }

  void removeExistingImage(int index) {
    existingImages.removeAt(index);
    onExistingImagesChanged?.call(existingImages);
    notifyListeners();
  }

  // ------------------------------
  // Tag Change
  // ------------------------------
  void changeTag(TagModel tag) {
    selectedTag = tag;
    onTagChanged?.call(tag);
    notifyListeners();
  }
}
