import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/tags_moedl.dart';
import 'package:of_course/feature/course/models/course_set_model.dart';

class EditCourseViewModel extends ChangeNotifier {
  final SupabaseManager supabase = SupabaseManager.shared;
  late int courseId;
  // -----------------------------
  // State
  // -----------------------------
  List<CourseSetData> sets = [];
  List<bool> highlightList = [];
  List<int> existingSetIds = [];
  List<int> deletedSetIds = [];
  List<List<String>> originalImageUrls = [];

  List<TagModel> tagList = [];

  String title = "";
  bool isLoading = false;

  static const _naverClientId = 'sr1eyuomlk';
  static const _naverClientSecret = 'XtMhndnqfc7MFpLU81jxfzvivP0LNJbSIu2wphec';
  static const _kakaoRestKey = '05df8363e23a77cc74e7c20a667b6c7e';

  // -----------------------------
  // Init
  // -----------------------------
  Future<void> init(int courseId) async {
    isLoading = true;
    notifyListeners();
    this.courseId = courseId;
    tagList = await supabase.getTags();
    await _loadCourse(courseId);

    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadCourse(int courseId) async {
    final data = await supabase.getCourseForEdit(courseId);
    if (data == null) return;

    title = data['title'];

    for (var s in data['sets']) {
      final images = List<String>.from(s['images'] ?? []);

      final model = CourseSetData()
        ..query = s['query']
        ..lat = s['lat']
        ..lng = s['lng']
        ..gu = s['gu']
        ..tagId = s['tag_id']
        ..description = s['description']
        ..existingImages = List<String>.from(images);

      sets.add(model);
      highlightList.add(false);
      existingSetIds.add(s['id']);
      originalImageUrls.add(List<String>.from(images));
    }
    notifyListeners();
  }

  // -----------------------------
  // Update helpers (WriteCourse와 동일 구조)
  // -----------------------------
  void updateTag(int index, TagModel tag) {
    sets[index].tagId = tag.id;
    notifyListeners();
  }

  void updateDescription(int index, String text) {
    sets[index].description = text;
    notifyListeners();
  }

  void updateNewImages(int index, List<File> images) {
    sets[index].images = images;
    notifyListeners();
  }

  void updateExistingImages(int index, List<String> urls) {
    sets[index].existingImages = urls;
    notifyListeners();
  }

  void updateLatLng(int index, double lat, double lng) {
    sets[index].lat = lat;
    sets[index].lng = lng;
    notifyListeners();
  }

  // -----------------------------
  // Location
  // -----------------------------
  Future<void> updateLocation(int index, String query) async {
    final loc1 = await _getLatLngFromNaver(query);
    final loc2 = await _getLatLngFromKakao(query);
    final loc = loc1 ?? loc2;

    if (loc == null) return;

    sets[index].query = query;
    sets[index].lat = loc['lat'];
    sets[index].lng = loc['lng'];
    notifyListeners();
  }

  Future<Map<String, double>?> _getLatLngFromNaver(String query) async {
    try {
      final url = Uri.parse(
        'https://maps.apigw.ntruss.com/map-geocode/v2/geocode?query=${Uri.encodeQueryComponent(query)}',
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'x-ncp-apigw-api-key-id': _naverClientId,
          'x-ncp-apigw-api-key': _naverClientSecret,
        },
      );

      final data = jsonDecode(response.body);
      final list = data['addresses'] as List;

      if (list.isEmpty) return null;

      final f = list[0];
      return {'lat': double.parse(f['y']), 'lng': double.parse(f['x'])};
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, double>?> _getLatLngFromKakao(String query) async {
    try {
      final url = Uri.parse(
        'https://dapi.kakao.com/v2/local/search/keyword.json?query=${Uri.encodeQueryComponent(query)}',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'KakaoAK $_kakaoRestKey'},
      );

      final list = jsonDecode(response.body)['documents'] as List;
      if (list.isEmpty) return null;

      final f = list[0];
      return {'lat': double.parse(f['y']), 'lng': double.parse(f['x'])};
    } catch (_) {
      return null;
    }
  }

  // -----------------------------
  // Add / Remove set
  // -----------------------------
  void addSet() {
    sets.add(CourseSetData());
    highlightList.add(false);
    originalImageUrls.add([]);
    notifyListeners();
  }

  void removeSet(int index) {
    if (index < existingSetIds.length) {
      deletedSetIds.add(existingSetIds[index]);
      existingSetIds.removeAt(index);
    }

    sets.removeAt(index);
    highlightList.removeAt(index);
    if (index < originalImageUrls.length) {
      originalImageUrls.removeAt(index);
    }

    notifyListeners();
  }

  // -----------------------------
  // Storage delete
  // -----------------------------
  Future<void> deleteStorageImage(String url) async {
    if (url == "null" || url.isEmpty) return;

    try {
      final uri = Uri.parse(url);
      final seg = uri.pathSegments;

      final idx = seg.indexOf("public");
      if (idx == -1 || idx + 2 >= seg.length) return;

      final bucket = seg[idx + 1];
      final objectPath = seg.sublist(idx + 2).join('/');

      await supabase.supabase.storage.from(bucket).remove([objectPath]);
      debugPrint("🧹 삭제 성공: $objectPath");
    } catch (e) {
      debugPrint("❌ 삭제 실패: $e");
    }
  }

  // -----------------------------
  // Save Edit
  // -----------------------------
  Future<bool> saveEdit() async {
    List<int?> updatedSetIds = [];

    for (int i = 0; i < sets.length; i++) {
      final set = sets[i];
      final oldId = i < existingSetIds.length ? existingSetIds[i] : null;

      final original = originalImageUrls[i];
      final current = List<String>.from(set.existingImages);

      final toDelete = original.where((u) => !current.contains(u)).toList();

      for (final url in toDelete) {
        await deleteStorageImage(url);
      }

      List<String> uploaded = [];
      for (final file in set.images) {
        final u = await supabase.uploadCourseSetImage(file);
        if (u != null) uploaded.add(u);
      }

      final allImages = [...current, ...uploaded];
      final img1 = allImages.isNotEmpty ? allImages[0] : null;
      final img2 = allImages.length > 1 ? allImages[1] : null;
      final img3 = allImages.length > 2 ? allImages[2] : null;

      if (oldId != null) {
        await supabase.supabase
            .from('course_sets')
            .update({
              'img_01': img1,
              'img_02': img2,
              'img_03': img3,
              'tag': set.tagId,
              'address': set.query,
              'lat': set.lat,
              'lng': set.lng,
              'gu': set.gu,
              'description': set.description,
            })
            .eq('id', oldId);

        updatedSetIds.add(oldId);
      } else {
        final newId = await supabase.insertCourseSet(
          img1: img1,
          img2: img2,
          img3: img3,
          address: set.query ?? "",
          lat: set.lat,
          lng: set.lng,
          gu: set.gu,
          tagId: set.tagId,
          description: set.description,
        );
        updatedSetIds.add(newId);
      }
    }

    for (final id in deletedSetIds) {
      await supabase.supabase.from('course_sets').delete().eq('id', id);
    }

    await supabase.supabase
        .from('courses')
        .update({
          'title': title,
          'set_01': updatedSetIds.length > 0 ? updatedSetIds[0] : null,
          'set_02': updatedSetIds.length > 1 ? updatedSetIds[1] : null,
          'set_03': updatedSetIds.length > 2 ? updatedSetIds[2] : null,
          'set_04': updatedSetIds.length > 3 ? updatedSetIds[3] : null,
          'set_05': updatedSetIds.length > 4 ? updatedSetIds[4] : null,
        })
        .eq('id', courseId);

    return true;
  }
}
