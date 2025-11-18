import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/tags_moedl.dart';
import 'package:of_course/feature/course/models/course_set_model.dart';

class EditCourseViewModel extends ChangeNotifier {
  final int courseId;

  EditCourseViewModel({required this.courseId});

  // UI state
  final ScrollController scrollController = ScrollController();
  final GlobalKey mapKey = GlobalKey(debugLabel: "edit_map_key");

  NaverMapController? mapController;

  final List<CourseSetData> courseSetData = [];
  final List<bool> highlightList = [];
  final List<int> existingSetIds = [];
  final List<int> deletedSetIds = [];
  final List<List<String>> originalImageUrls = [];
  final Map<int, String> markerIdBySet = {};

  final TextEditingController titleController = TextEditingController();

  List<TagModel> tagList = [];

  // APIs
  static const _kakaoRestKey = '05df8363e23a77cc74e7c20a667b6c7e';
  static const _naverId = 'sr1eyuomlk';
  static const _naverSecret = 'XtMhndnqfc7MFpLU81jxfzvivP0LNJbSIu2wphec';

  // INIT
  Future<void> init() async {
    tagList = await SupabaseManager.shared.getTags();
    await _loadCourse();
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // LOAD COURSE
  // ─────────────────────────────────────────────
  Future<void> _loadCourse() async {
    final data = await SupabaseManager.shared.getCourseForEdit(courseId);
    if (data == null) return;

    titleController.text = data['title'];

    for (var s in data['sets']) {
      final List<String> imgs = List<String>.from(s['images'] ?? []);

      courseSetData.add(
        CourseSetData()
          ..query = s['query']
          ..lat = s['lat']
          ..lng = s['lng']
          ..gu = s['gu']
          ..tagId = s['tag_id']
          ..description = s['description']
          ..existingImages = List<String>.from(imgs),
      );

      existingSetIds.add(s['id']);
      highlightList.add(false);
      originalImageUrls.add(List.from(imgs));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMarkersForExistingSets();
    });
  }

  // MARKERS 복원
  Future<void> _initMarkersForExistingSets() async {
    if (mapController == null) return;

    List<NLatLng> pos = [];

    for (int i = 0; i < courseSetData.length; i++) {
      final set = courseSetData[i];
      if (set.lat == null || set.lng == null) continue;

      final id = "marker_$i";
      final marker = NMarker(id: id, position: NLatLng(set.lat!, set.lng!));

      await mapController!.addOverlay(marker);

      markerIdBySet[i] = id;
      pos.add(NLatLng(set.lat!, set.lng!));
    }

    if (pos.isNotEmpty) {
      double minLat = pos.first.latitude;
      double maxLat = pos.first.latitude;
      double minLng = pos.first.longitude;
      double maxLng = pos.first.longitude;

      for (var p in pos) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }

      await mapController!.updateCamera(
        NCameraUpdate.fitBounds(
          NLatLngBounds(
            southWest: NLatLng(minLat, minLng),
            northEast: NLatLng(maxLat, maxLng),
          ),
          padding: const EdgeInsets.all(80),
        ),
      );
    }
  }

  // MAP READY
  void onMapReady(NaverMapController c) {
    mapController = c;
    _initMarkersForExistingSets();
  }

  // LOCATION SEARCH
  Future<NLatLng?> _getLatLngFromAddress(String query) async {
    try {
      final url = Uri.parse(
        'https://maps.apigw.ntruss.com/map-geocode/v2/geocode?query=${Uri.encodeQueryComponent(query)}',
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'x-ncp-apigw-api-key-id': _naverId,
          'x-ncp-apigw-api-key': _naverSecret,
        },
      );

      final data = jsonDecode(response.body);
      if (data['addresses'] != null && data['addresses'].isNotEmpty) {
        return NLatLng(
          double.parse(data['addresses'][0]['y']),
          double.parse(data['addresses'][0]['x']),
        );
      }
    } catch (_) {}
    return null;
  }

  Future<NLatLng?> _getLatLngFromKakao(String query) async {
    try {
      final url = Uri.parse(
        'https://dapi.kakao.com/v2/local/search/keyword.json?query=${Uri.encodeQueryComponent(query)}',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'KakaoAK $_kakaoRestKey'},
      );

      final docs = jsonDecode(response.body)['documents'] as List;
      if (docs.isNotEmpty) {
        return NLatLng(double.parse(docs[0]['y']), double.parse(docs[0]['x']));
      }
    } catch (_) {}

    return null;
  }

  Future<void> onSearch(int index, String query) async {
    NLatLng? loc = await _getLatLngFromAddress(query);
    loc ??= await _getLatLngFromKakao(query);
    if (loc == null) return;

    courseSetData[index].query = query;
    courseSetData[index].lat = loc.latitude;
    courseSetData[index].lng = loc.longitude;

    await _removeMarkerIfExists(index);

    final id = "edit_marker_$index";
    await mapController?.addOverlay(NMarker(id: id, position: loc));

    markerIdBySet[index] = id;

    await mapController?.updateCamera(
      NCameraUpdate.scrollAndZoomTo(target: loc, zoom: 15),
    );

    notifyListeners();
  }

  Future<void> onLocationSaved(int index, double lat, double lng) async {
    courseSetData[index].lat = lat;
    courseSetData[index].lng = lng;
    notifyListeners();
  }

  Future<void> _removeMarkerIfExists(int index) async {
    final oldId = markerIdBySet[index];
    if (oldId == null) return;

    await mapController?.deleteOverlay(
      NOverlayInfo(id: oldId, type: NOverlayType.marker),
    );

    markerIdBySet.remove(index);
  }

  // IMAGE HANDLER
  void updateImages(int index, List<File> images) {
    courseSetData[index].images = images;
    notifyListeners();
  }

  void updateExistingImages(int index, List<String> urls) {
    courseSetData[index].existingImages = urls;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // 스크롤 / 맵 위치 이동 (WriteCourseViewModel이랑 맞추기)
  // ─────────────────────────────────────────────
  void scrollToOffset(double offsetY) {
    scrollController.animateTo(
      offsetY - 20,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void scrollToMap() {
    final ctx = mapKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } else {
      scrollController.animateTo(
        300,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void updateDescription(int index, String txt) {
    courseSetData[index].description = txt;
  }

  void updateTag(int index, TagModel tag) {
    courseSetData[index].tagId = tag.id;
    notifyListeners();
  }

  // ADD SET
  void addSet() {
    courseSetData.add(CourseSetData());
    highlightList.add(false);
    originalImageUrls.add([]);
    notifyListeners();
  }

  // DELETE SET
  Future<void> removeLastSet() async {
    final index = courseSetData.length - 1;

    for (final url in originalImageUrls[index]) {
      await _deleteImageFromStorage(url);
    }

    await _removeMarkerIfExists(index);

    if (existingSetIds.length > index) {
      deletedSetIds.add(existingSetIds[index]);
      existingSetIds.removeAt(index);
    }

    courseSetData.removeLast();
    highlightList.removeLast();
    originalImageUrls.removeLast();

    notifyListeners();
  }

  // DELETE IMAGE FROM STORAGE
  Future<void> _deleteImageFromStorage(String publicUrl) async {
    if (publicUrl == "null" || publicUrl.isEmpty) return;

    const base =
        "https://dbhecolzljfrmgtdjwie.supabase.co/storage/v1/object/public/course_set_image/";

    if (!publicUrl.startsWith(base)) return;

    final filePath = publicUrl.substring(base.length);

    await SupabaseManager.shared.supabase.storage
        .from("course_set_image")
        .remove([filePath]);
  }

  // SAVE EDIT
  Future<void> saveEdit(BuildContext context) async {
    List<int?> setIds = [];

    for (int i = 0; i < courseSetData.length; i++) {
      final set = courseSetData[i];
      final oldId = i < existingSetIds.length ? existingSetIds[i] : null;

      final original = i < originalImageUrls.length
          ? originalImageUrls[i]
          : <String>[];

      final current = List<String>.from(set.existingImages);

      final deleted = original.where((e) => !current.contains(e)).toList();

      for (final url in deleted) {
        await _deleteImageFromStorage(url);
      }

      List<String> uploaded = [];
      for (final f in set.images) {
        final uploadedUrl = await SupabaseManager.shared.uploadCourseSetImage(
          f,
        );
        if (uploadedUrl != null) uploaded.add(uploadedUrl);
      }

      final finalImages = [...current, ...uploaded];

      String? img1 = finalImages.isNotEmpty ? finalImages[0] : null;
      String? img2 = finalImages.length > 1 ? finalImages[1] : null;
      String? img3 = finalImages.length > 2 ? finalImages[2] : null;

      if (oldId != null) {
        await SupabaseManager.shared.supabase
            .from("course_sets")
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
            .eq("id", oldId);

        setIds.add(oldId);
      } else {
        final newId = await SupabaseManager.shared.insertCourseSet(
          img1: img1,
          img2: img2,
          img3: img3,
          address: set.query ?? "",
          lat: set.lat!,
          lng: set.lng!,
          gu: set.gu,
          tagId: set.tagId,
          description: set.description,
        );
        setIds.add(newId);
      }
    }

    // 삭제된 세트 제거
    for (final id in deletedSetIds) {
      await SupabaseManager.shared.supabase
          .from("course_sets")
          .delete()
          .eq("id", id);
    }

    // course 업데이트
    await SupabaseManager.shared.supabase
        .from("courses")
        .update({
          'title': titleController.text,
          'set_01': setIds.isNotEmpty ? setIds[0] : null,
          'set_02': setIds.length > 1 ? setIds[1] : null,
          'set_03': setIds.length > 2 ? setIds[2] : null,
          'set_04': setIds.length > 3 ? setIds[3] : null,
          'set_05': setIds.length > 4 ? setIds[4] : null,
        })
        .eq("id", courseId);

    if (context.mounted) context.pop(true);
  }

  // 뒤로가기 확인
  Future<bool> onWillPop(BuildContext context) async {
    final ok = await _confirm(context, "코스 수정을 취소하시겠습니까?\n수정 전 상태로 돌아갑니다.");
    if (ok) context.pop(false);
    return false;
  }

  Future<bool> _confirm(BuildContext context, String title) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (_) {
            return AlertDialog(
              title: const Text("알림"),
              content: Text(title),
              actions: [
                TextButton(
                  child: const Text("취소"),
                  onPressed: () => Navigator.pop(context, false),
                ),
                ElevatedButton(
                  child: const Text("확인"),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
