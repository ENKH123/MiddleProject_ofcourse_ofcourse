import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/tags_moedl.dart';
import 'package:of_course/feature/course/models/course_set_model.dart';

class WriteCourseViewModel extends ChangeNotifier {
  // ─────────────────────────────────────────────────────────────
  // 기본 데이터
  // ─────────────────────────────────────────────────────────────
  final ScrollController scrollController = ScrollController();
  final GlobalKey mapKey = GlobalKey(debugLabel: "write_map_key");

  final List<CourseSetData> courseSetData = [];
  final List<bool> highlightList = [];
  final List<int> existingSetIds = [];
  final List<int> deletedSetIds = [];
  final List<List<String>> originalImageUrls = [];
  final Map<int, String> markerIdBySet = {};

  List<TagModel> tagList = [];

  final TextEditingController titleController = TextEditingController();
  NaverMapController? mapController;

  int? continueCourseId;

  // API KEY
  static const _naverClientId = 'sr1eyuomlk';
  static const _naverClientSecret = 'XtMhndnqfc7MFpLU81jxfzvivP0LNJbSIu2wphec';
  static const _kakaoRestKey = '05df8363e23a77cc74e7c20a667b6c7e';

  // ─────────────────────────────────────────────────────────────
  // 초기화
  // ─────────────────────────────────────────────────────────────
  Future<void> init(int? continueCourseId) async {
    this.continueCourseId = continueCourseId;
    await _loadTags();

    if (continueCourseId != null) {
      await _loadContinueCourse(continueCourseId);
    } else {
      for (int i = 0; i < 2; i++) {
        courseSetData.add(CourseSetData());
        highlightList.add(false);
        originalImageUrls.add([]);
      }
    }

    notifyListeners();
  }

  Future<void> _loadTags() async {
    tagList = await SupabaseManager.shared.getTags();
  }

  bool isUploading = false;
  void setUploading(bool value) {
    isUploading = value;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // Continue 모드 데이터 로드
  // ─────────────────────────────────────────────────────────────
  Future<void> _loadContinueCourse(int courseId) async {
    final data = await SupabaseManager.shared.getCourseDetailForContinue(
      courseId,
    );
    if (data == null) return;

    titleController.text = data['title'];

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

      existingSetIds.add(s['id']);
      courseSetData.add(model);
      highlightList.add(false);
      originalImageUrls.add(List<String>.from(images));
    }

    while (courseSetData.length < 2) {
      courseSetData.add(CourseSetData());
      highlightList.add(false);
      originalImageUrls.add([]);
    }

    // UI 그려진 후 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMarkersForExistingSets();
    });
  }

  Future<void> _initMarkersForExistingSets() async {
    if (mapController == null) return;

    List<NLatLng> positions = [];

    for (int i = 0; i < courseSetData.length; i++) {
      final set = courseSetData[i];
      if (set.lat == null || set.lng == null) continue;

      final markerId = "existing_marker_$i";
      final marker = NMarker(
        id: markerId,
        position: NLatLng(set.lat!, set.lng!),
      );

      await mapController!.addOverlay(marker);
      markerIdBySet[i] = markerId;
      positions.add(NLatLng(set.lat!, set.lng!));
    }

    if (positions.isNotEmpty) {
      double minLat = positions.first.latitude;
      double maxLat = positions.first.latitude;
      double minLng = positions.first.longitude;
      double maxLng = positions.first.longitude;

      for (var p in positions) {
        minLat = p.latitude < minLat ? p.latitude : minLat;
        maxLat = p.latitude > maxLat ? p.latitude : maxLat;
        minLng = p.longitude < minLng ? p.longitude : minLng;
        maxLng = p.longitude > maxLng ? p.longitude : maxLng;
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

  // ─────────────────────────────────────────────────────────────
  // 지도 준비
  // ─────────────────────────────────────────────────────────────
  void onMapReady(NaverMapController controller) {
    mapController = controller;
  }

  // ─────────────────────────────────────────────────────────────
  // Highlight 애니메이션
  // ─────────────────────────────────────────────────────────────
  void highlight(int index) {
    highlightList[index] = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 600), () {
      highlightList[index] = false;
      notifyListeners();
    });
  }

  void scrollToOffset(double offsetY) {
    scrollController.animateTo(
      offsetY - 20,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void scrollToSet(int index) {
    scrollController.animateTo(
      index * 450,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 검색 → 주소 → 위경도 변환
  // ─────────────────────────────────────────────────────────────
  Future<NLatLng?> _getLatLngFromAddress(String query) async {
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
      if ((data['addresses'] as List).isNotEmpty) {
        final first = data['addresses'][0];
        return NLatLng(double.parse(first['y']), double.parse(first['x']));
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
        final first = docs.first;
        return NLatLng(double.parse(first['y']), double.parse(first['x']));
      }
    } catch (_) {}

    return null;
  }

  Future<void> handleSearch(int index, String query) async {
    NLatLng? location = await _getLatLngFromAddress(query);
    location ??= await _getLatLngFromKakao(query);

    if (location == null) {
      _showMessage("위치를 찾을 수 없어요.");
      return;
    }

    final set = courseSetData[index];
    set.query = query;
    set.lat = location.latitude;
    set.lng = location.longitude;

    await _removeMarkerIfExists(index);

    final markerId = 'set_marker_$index';
    final marker = NMarker(
      id: markerId,
      position: location,
      caption: NOverlayCaption(text: query),
    );

    await mapController?.addOverlay(marker);
    markerIdBySet[index] = markerId;

    await mapController?.updateCamera(
      NCameraUpdate.scrollAndZoomTo(target: location, zoom: 15),
    );

    notifyListeners();
  }

  Future<void> handleLocationSaved(int index, double lat, double lng) async {
    courseSetData[index].lat = lat;
    courseSetData[index].lng = lng;
    notifyListeners();
  }

  Future<void> _removeMarkerIfExists(int index) async {
    final oldId = markerIdBySet[index];
    if (oldId == null || mapController == null) return;

    final info = NOverlayInfo(type: NOverlayType.marker, id: oldId);
    await mapController!.deleteOverlay(info);
    markerIdBySet.remove(index);
  }

  // ─────────────────────────────────────────────────────────────
  // 이미지 관리
  // ─────────────────────────────────────────────────────────────
  void updateImages(int index, List<File> images) {
    courseSetData[index].images = images;
    notifyListeners();
  }

  void updateExistingImages(int index, List<String> list) {
    courseSetData[index].existingImages = list;
    notifyListeners();
  }

  void updateDescription(int index, String txt) {
    courseSetData[index].description = txt;
  }

  void updateTag(int index, TagModel tag) {
    courseSetData[index].tagId = tag.id;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // 세트 추가 / 삭제
  // ─────────────────────────────────────────────────────────────
  void addSet() {
    courseSetData.add(CourseSetData());
    highlightList.add(false);
    originalImageUrls.add([]);
    notifyListeners();
  }

  Future<void> removeLastSet() async {
    final index = courseSetData.length - 1;

    await _removeMarkerIfExists(index);

    if (index < originalImageUrls.length) {
      for (final url in originalImageUrls[index]) {
        await _deleteImageFromStorage(url);
      }
      originalImageUrls.removeAt(index);
    }

    if (index < existingSetIds.length) {
      deletedSetIds.add(existingSetIds[index]);
      existingSetIds.removeAt(index);
    }

    courseSetData.removeAt(index);
    highlightList.removeAt(index);
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // Storage 이미지 삭제
  // ─────────────────────────────────────────────────────────────
  Future<void> _deleteImageFromStorage(String publicUrl) async {
    if (publicUrl == "null" || publicUrl.isEmpty) return;

    try {
      final uri = Uri.parse(publicUrl);
      final segments = uri.pathSegments;

      final publicIndex = segments.indexOf('public');
      if (publicIndex == -1 || publicIndex + 2 >= segments.length) {
        debugPrint('❌ URL 파싱 실패: $publicUrl');
        return;
      }

      final bucket = segments[publicIndex + 1];
      final objectPath = segments.sublist(publicIndex + 2).join('/');

      debugPrint('🧹 Storage 삭제 시도: bucket=$bucket, path=$objectPath');

      final res = await SupabaseManager.shared.supabase.storage
          .from(bucket)
          .remove([objectPath]);

      debugPrint('🧹 Storage 삭제 결과: $res');
    } catch (e, st) {
      debugPrint('❌ Storage 삭제 오류: $e\n$st');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Validation
  // ─────────────────────────────────────────────────────────────
  bool validate() {
    for (int i = 0; i < courseSetData.length; i++) {
      final set = courseSetData[i];

      if (set.lat == null || set.lng == null) {
        scrollToSet(i);
        highlight(i);
        _showMessage("세트 ${i + 1}: 위치 검색을 완료해주세요.");
        return false;
      }
      if (set.description == null || set.description!.trim().isEmpty) {
        scrollToSet(i);
        highlight(i);
        _showMessage("세트 ${i + 1}: 내용을 입력해주세요.");
        return false;
      }
      if (set.tagId == null) {
        scrollToSet(i);
        highlight(i);
        _showMessage("세트 ${i + 1}: 태그를 선택해주세요.");
        return false;
      }
    }
    return true;
  }

  // ─────────────────────────────────────────────────────────────
  // UI 보조 기능
  // ─────────────────────────────────────────────────────────────
  void scrollToMap() {
    final ctx = mapKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _showMessage(String msg) {
    final ctx = mapKey.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _showConfirmDialog(BuildContext context, String title) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          useRootNavigator: false,
          builder: (ctx) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 290,
                  padding: const EdgeInsets.symmetric(
                    vertical: 22,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit, size: 40, color: Colors.orange),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx, true),
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "확인",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx, false),
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text("취소"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ) ??
        false;
  }

  // ─────────────────────────────────────────────────────────────
  // 뒤로가기 처리
  // ─────────────────────────────────────────────────────────────
  Future<bool> handleBackPressed() async {
    final context = mapKey.currentContext!;
    final ok = await _showConfirmDialog(context, "코스 작성을 취소하시겠습니까?");

    if (ok) {
      context.pushReplacement('/home');
      return false;
    }
    return false;
  }

  void onCancelPressed(BuildContext context) async {
    final ok = await _showConfirmDialog(context, "작성 중인 내용을 취소하시겠습니까?");
    if (ok) context.push('/home');
  }

  // ─────────────────────────────────────────────────────────────
  // 업로드 버튼
  // ─────────────────────────────────────────────────────────────
  void onUploadPressed() async {
    final context = mapKey.currentContext!;
    if (!validate()) return;

    setUploading(true); // 🔥 로딩 시작

    try {
      if (continueCourseId != null) {
        await _continuesaveEdit(true);
      } else {
        await _saveNew(true);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("코스 업로드 완료 🎉")));
        context.push('/home');
      }
    } catch (e, st) {
      debugPrint("❌ 업로드 오류: $e\n$st");
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("업로드 중 오류가 발생했습니다.")));
      }
    } finally {
      setUploading(false); // 🔥 로딩 종료
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 임시저장
  // ─────────────────────────────────────────────────────────────
  void onTempSave() async {
    final context = mapKey.currentContext!;
    final ok = await _showConfirmDialog(context, "임시저장하시겠습니까?");
    if (!ok) return;

    if (continueCourseId != null) {
      await _continuesaveEdit(false);
    } else {
      await _saveNew(false);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("임시 저장 완료")));
      context.push('/home');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 새 코스 저장
  // ─────────────────────────────────────────────────────────────
  Future<void> _saveNew(bool isDone) async {
    final userID = await SupabaseManager.shared.getMyUserRowId();

    List<int?> setIds = [];

    for (final set in courseSetData) {
      String? img1, img2, img3;

      if (set.images.isNotEmpty) {
        img1 = await SupabaseManager.shared.uploadCourseSetImage(set.images[0]);
      }
      if (set.images.length > 1) {
        img2 = await SupabaseManager.shared.uploadCourseSetImage(set.images[1]);
      }
      if (set.images.length > 2) {
        img3 = await SupabaseManager.shared.uploadCourseSetImage(set.images[2]);
      }

      final id = await SupabaseManager.shared.insertCourseSet(
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
      setIds.add(id);
    }

    await SupabaseManager.shared.supabase.from('courses').insert({
      'title': titleController.text,
      'user_id': userID,
      'set_01': setIds.length > 0 ? setIds[0] : null,
      'set_02': setIds.length > 1 ? setIds[1] : null,
      'set_03': setIds.length > 2 ? setIds[2] : null,
      'set_04': setIds.length > 3 ? setIds[3] : null,
      'set_05': setIds.length > 4 ? setIds[4] : null,
      'is_done': isDone,
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Continue Edit 저장
  // ─────────────────────────────────────────────────────────────
  Future<void> _continuesaveEdit(bool isDone) async {
    if (continueCourseId == null) return;

    List<int?> setIds = [];

    for (int i = 0; i < courseSetData.length; i++) {
      final set = courseSetData[i];
      final oldId = i < existingSetIds.length ? existingSetIds[i] : null;

      final List<String> original = i < originalImageUrls.length
          ? originalImageUrls[i]
          : <String>[];
      final List<String> currentExisting = List<String>.from(
        set.existingImages,
      );

      final deletedUrls = original
          .where((url) => !currentExisting.contains(url))
          .toList();

      for (final url in deletedUrls) {
        await _deleteImageFromStorage(url);
      }

      List<String> uploaded = [];
      for (final f in set.images) {
        final u = await SupabaseManager.shared.uploadCourseSetImage(f);
        if (u != null) uploaded.add(u);
      }

      final List<String> finalImages = [...currentExisting, ...uploaded];

      String? img1 = finalImages.isNotEmpty ? finalImages[0] : null;
      String? img2 = finalImages.length > 1 ? finalImages[1] : null;
      String? img3 = finalImages.length > 2 ? finalImages[2] : null;

      if (oldId != null) {
        await SupabaseManager.shared.supabase
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

        setIds.add(oldId);
      } else {
        final newId = await SupabaseManager.shared.insertCourseSet(
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
    }

    for (final del in deletedSetIds) {
      await SupabaseManager.shared.supabase
          .from('course_sets')
          .delete()
          .eq('id', del);
    }

    await SupabaseManager.shared.supabase
        .from('courses')
        .update({
          'title': titleController.text,
          'set_01': setIds.length > 0 ? setIds[0] : null,
          'set_02': setIds.length > 1 ? setIds[1] : null,
          'set_03': setIds.length > 2 ? setIds[2] : null,
          'set_04': setIds.length > 3 ? setIds[3] : null,
          'set_05': setIds.length > 4 ? setIds[4] : null,
          'is_done': isDone,
        })
        .eq('id', continueCourseId!);
  }
}
