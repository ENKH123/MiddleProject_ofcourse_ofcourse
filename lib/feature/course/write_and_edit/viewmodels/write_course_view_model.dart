import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/tags_moedl.dart';
import 'package:of_course/feature/course/models/course_set_model.dart';

class WriteCourseViewModel extends ChangeNotifier {
  final SupabaseManager supabase = SupabaseManager.shared;

  List<CourseSetData> sets = [];
  List<bool> highlightList = [];
  List<int> existingSetIds = [];
  List<int> deletedSetIds = [];
  List<List<String>> originalImageUrls = []; // 처음 로드한 기존 이미지들

  List<TagModel> tagList = [];

  String title = "";
  bool isLoading = false;

  // ⭐ WriteCoursePage에서 필요하던 continueCourseId 추가!
  int? continueCourseId;

  // API 키
  static const _naverClientId = 'sr1eyuomlk';
  static const _naverClientSecret = 'XtMhndnqfc7MFpLU81jxfzvivP0LNJbSIu2wphec';
  static const _kakaoRestKey = '05df8363e23a77cc74e7c20a667b6c7e';

  // ------------------------------------------------------
  // INIT
  // ------------------------------------------------------
  Future<void> init(int? continueCourseId) async {
    this.continueCourseId = continueCourseId;

    isLoading = true;
    notifyListeners();

    await loadTags();

    if (continueCourseId != null) {
      await loadContinueCourse(continueCourseId);
    } else {
      for (int i = 0; i < 2; i++) {
        sets.add(CourseSetData());
        highlightList.add(false);
        originalImageUrls.add([]);
      }
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadTags() async {
    tagList = await supabase.getTags();
    notifyListeners();
  }

  Future<void> loadContinueCourse(int courseId) async {
    final data = await supabase.getCourseDetailForContinue(courseId);
    if (data == null) return;

    title = data['title'];

    for (var s in data['sets']) {
      final imgList = List<String>.from(s['images'] ?? []);

      final model = CourseSetData()
        ..query = s['query']
        ..lat = s['lat']
        ..lng = s['lng']
        ..gu = s['gu']
        ..tagId = s['tag_id']
        ..description = s['description']
        ..existingImages = List<String>.from(imgList);

      sets.add(model);
      highlightList.add(false);
      originalImageUrls.add(List<String>.from(imgList));

      existingSetIds.add(s['id']);
    }

    // 최소 2개 보장
    while (sets.length < 2) {
      sets.add(CourseSetData());
      highlightList.add(false);
      originalImageUrls.add([]);
    }

    notifyListeners();
  }

  // ------------------------------------------------------
  // 검색 → lat/lng 업데이트
  // ------------------------------------------------------
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

  // 네이버
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

  // 카카오
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

  // ------------------------------------------------------
  // ⭐ WriteCoursePage가 요구하는 UPDATE 메서드들
  // ------------------------------------------------------

  void updateTag(int index, TagModel tag) {
    sets[index].tagId = tag.id;
    notifyListeners();
  }

  void updateDescription(int index, String text) {
    sets[index].description = text;
    notifyListeners();
  }

  void updateNewImages(int index, List<File> images) {
    sets[index].images = images; // 새 이미지
    notifyListeners();
  }

  void updateExistingImages(int index, List<String> urls) {
    sets[index].existingImages = urls; // 기존 이미지
    notifyListeners();
  }

  void updateLatLng(int index, double lat, double lng) {
    sets[index].lat = lat;
    sets[index].lng = lng;
    notifyListeners();
  }

  // ------------------------------------------------------
  // 세트 관리
  // ------------------------------------------------------
  void addSet() {
    sets.add(CourseSetData());
    highlightList.add(false);
    originalImageUrls.add([]);
    notifyListeners();
  }

  void deleteSet(int index) {
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

  // ------------------------------------------------------
  // 이미지 삭제
  // ------------------------------------------------------
  Future<void> _deleteImageFromStorage(String publicUrl) async {
    if (publicUrl == "null" || publicUrl.trim().isEmpty) return;

    try {
      final uri = Uri.parse(publicUrl);
      final seg = uri.pathSegments;

      final publicIdx = seg.indexOf('public');
      if (publicIdx == -1 || publicIdx + 2 >= seg.length) return;

      final bucket = seg[publicIdx + 1];
      final objectPath = seg.sublist(publicIdx + 2).join('/');

      debugPrint('🧹 삭제 요청: bucket=$bucket, path=$objectPath');

      final res = await supabase.supabase.storage.from(bucket).remove([
        objectPath,
      ]);

      debugPrint("🧹 삭제 결과: $res");
    } catch (e) {
      debugPrint('❌ 이미지 삭제 실패: $e');
    }
  }

  // ------------------------------------------------------
  // 검증
  // ------------------------------------------------------
  bool validate() {
    for (int i = 0; i < sets.length; i++) {
      final s = sets[i];

      if (s.lat == null || s.lng == null) return false;
      if (s.description == null || s.description!.trim().isEmpty) return false;
      if (s.tagId == null) return false;
    }
    return true;
  }

  // ------------------------------------------------------
  // 신규 저장
  // ------------------------------------------------------
  Future<bool> saveNew(bool isDone) async {
    final userRowId = await supabase.getMyUserRowId();

    List<int?> setIds = [];

    for (final set in sets) {
      String? img1, img2, img3;

      if (set.images.isNotEmpty)
        img1 = await supabase.uploadCourseSetImage(set.images[0]);
      if (set.images.length > 1)
        img2 = await supabase.uploadCourseSetImage(set.images[1]);
      if (set.images.length > 2)
        img3 = await supabase.uploadCourseSetImage(set.images[2]);

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

      setIds.add(newId);
    }

    await supabase.supabase.from('courses').insert({
      'title': title,
      'user_id': userRowId,
      'set_01': setIds.length > 0 ? setIds[0] : null,
      'set_02': setIds.length > 1 ? setIds[1] : null,
      'set_03': setIds.length > 2 ? setIds[2] : null,
      'set_04': setIds.length > 3 ? setIds[3] : null,
      'set_05': setIds.length > 4 ? setIds[4] : null,
      'is_done': isDone,
    });

    return true;
  }

  // ------------------------------------------------------
  // 이어쓰기 저장
  // ------------------------------------------------------
  Future<bool> saveContinue(int courseId, bool isDone) async {
    List<int?> newSetIds = [];

    for (int i = 0; i < sets.length; i++) {
      final set = sets[i];
      final oldId = i < existingSetIds.length ? existingSetIds[i] : null;

      final original = i < originalImageUrls.length
          ? originalImageUrls[i]
          : <String>[];
      final current = List<String>.from(set.existingImages);

      final deleted = original.where((u) => !current.contains(u)).toList();

      for (final url in deleted) {
        await _deleteImageFromStorage(url);
      }

      List<String> uploaded = [];
      for (final file in set.images) {
        final u = await supabase.uploadCourseSetImage(file);
        if (u != null) uploaded.add(u);
      }

      final allImages = [...current, ...uploaded];

      String? img1 = allImages.isNotEmpty ? allImages[0] : null;
      String? img2 = allImages.length > 1 ? allImages[1] : null;
      String? img3 = allImages.length > 2 ? allImages[2] : null;

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

        newSetIds.add(oldId);
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
        newSetIds.add(newId);
      }
    }

    // 삭제된 세트 제거
    for (final delId in deletedSetIds) {
      await supabase.supabase.from('course_sets').delete().eq('id', delId);
    }

    // Parent course update
    await supabase.supabase
        .from('courses')
        .update({
          'title': title,
          'set_01': newSetIds.length > 0 ? newSetIds[0] : null,
          'set_02': newSetIds.length > 1 ? newSetIds[1] : null,
          'set_03': newSetIds.length > 2 ? newSetIds[2] : null,
          'set_04': newSetIds.length > 3 ? newSetIds[3] : null,
          'set_05': newSetIds.length > 4 ? newSetIds[4] : null,
          'is_done': isDone,
        })
        .eq('id', courseId);

    return true;
  }
}
