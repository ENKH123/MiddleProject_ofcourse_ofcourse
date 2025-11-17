import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/tags_moedl.dart';
import 'package:of_course/feature/course/components/course_set.dart';
import 'package:of_course/feature/course/models/course_set_model.dart';

class EditCoursePage extends StatefulWidget {
  final int courseId;
  const EditCoursePage({super.key, required this.courseId});

  @override
  State<EditCoursePage> createState() => _EditCoursePageState();
}

class _EditCoursePageState extends State<EditCoursePage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _mapKey = GlobalKey(debugLabel: "edit_map_key");
  NaverMapController? _mapController;

  final Map<int, String> _markerIdBySet = {};
  final List<CourseSetData> _courseSetDataList = [];
  final List<bool> _highlightList = [];
  final List<int> _existingSetIds = [];
  final List<int> _deletedSetIds = []; // ✅ 삭제된 세트 추적 리스트

  /// ✅ 각 세트별 "원래 DB에서 가져온 이미지 URL 리스트"
  final List<List<String>> _originalImageUrls = [];

  List<TagModel> tagList = [];
  final TextEditingController _titleController = TextEditingController();

  static const _kakaoRestKey = '05df8363e23a77cc74e7c20a667b6c7e';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    tagList = await SupabaseManager.shared.getTags();
    await _loadCourse();
    setState(() {});
  }

  Future<void> _loadCourse() async {
    final data = await SupabaseManager.shared.getCourseForEdit(widget.courseId);
    if (data == null) return;

    _titleController.text = data['title'];

    for (var s in data['sets']) {
      final images = List<String>.from(s['images'] ?? []);

      final model = CourseSetData()
        ..query = s['query']
        ..lat = s['lat']
        ..lng = s['lng']
        ..gu = s['gu']
        ..tagId = s['tag_id']
        ..description = s['description']
        ..existingImages = List<String>.from(
          images,
        ); // ✅ 현재 유지 중인 URL 리스트(= for_update_url 역할)

      _existingSetIds.add(s['id']);
      _courseSetDataList.add(model);
      _highlightList.add(false);

      // ✅ "원래 DB 기준 이미지 리스트" 별도 보관
      _originalImageUrls.add(List<String>.from(images));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMarkersForExistingSets();
    });
  }

  Future<void> _initMarkersForExistingSets() async {
    if (_mapController == null) return;

    List<NLatLng> validPositions = [];

    for (int i = 0; i < _courseSetDataList.length; i++) {
      final set = _courseSetDataList[i];
      if (set.lat == null || set.lng == null) continue;

      final markerId = "existing_marker_$i";
      final marker = NMarker(
        id: markerId,
        position: NLatLng(set.lat!, set.lng!),
      );

      await _mapController!.addOverlay(marker);
      _markerIdBySet[i] = markerId;
      validPositions.add(NLatLng(set.lat!, set.lng!));
    }

    if (validPositions.isNotEmpty) {
      double minLat = validPositions.first.latitude;
      double maxLat = validPositions.first.latitude;
      double minLng = validPositions.first.longitude;
      double maxLng = validPositions.first.longitude;

      for (var p in validPositions) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }

      final bounds = NLatLngBounds(
        southWest: NLatLng(minLat, minLng),
        northEast: NLatLng(maxLat, maxLng),
      );

      await _mapController!.updateCamera(
        NCameraUpdate.fitBounds(bounds, padding: const EdgeInsets.all(80)),
      );
    }
  }

  void _scrollToMap() {
    final ctx = _mapKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        alignment: 0.0,
      );
    } else {
      _scrollController.animateTo(
        300,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<NLatLng?> _getLatLngFromAddress(String query) async {
    try {
      final url = Uri.parse(
        'https://maps.apigw.ntruss.com/map-geocode/v2/geocode?query=${Uri.encodeQueryComponent(query)}',
      );
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'x-ncp-apigw-api-key-id': 'sr1eyuomlk',
          'x-ncp-apigw-api-key': 'XtMhndnqfc7MFpLU81jxfzvivP0LNJbSIu2wphec',
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

  Future<void> _removeMarkerIfExists(int index) async {
    final oldId = _markerIdBySet[index];
    if (oldId == null || _mapController == null) return;
    await _mapController!.deleteOverlay(
      NOverlayInfo(id: oldId, type: NOverlayType.marker),
    );
    _markerIdBySet.remove(index);
  }

  Future<void> _handleLocationSelected(int index, String query) async {
    _scrollToMap();
    NLatLng? loc = await _getLatLngFromAddress(query);
    loc ??= await _getLatLngFromKakao(query);
    if (loc == null) return;

    final set = _courseSetDataList[index];
    set.query = query;
    set.lat = loc.latitude;
    set.lng = loc.longitude;

    await _removeMarkerIfExists(index);
    final id = "edit_marker_$index";
    await _mapController?.addOverlay(NMarker(id: id, position: loc));
    _markerIdBySet[index] = id;

    await _mapController?.updateCamera(
      NCameraUpdate.scrollAndZoomTo(target: loc, zoom: 15),
    );
  }

  void _addNewSet() {
    setState(() {
      _courseSetDataList.add(CourseSetData());
      _highlightList.add(false);
      _originalImageUrls.add([]); // ✅ 새 세트는 원본 이미지 없음
    });
  }

  /// ✅ Supabase Storage에서 public URL 기준으로 삭제
  Future<void> _deleteImageFromStorage(String publicUrl) async {
    if (publicUrl == "null" || publicUrl.isEmpty) return;

    // ✅ 버킷 루트까지만 포함한 baseUrl
    const String baseUrl =
        'https://dbhecolzljfrmgtdjwie.supabase.co/storage/v1/object/public/course_set_image/';

    if (!publicUrl.startsWith(baseUrl)) {
      debugPrint('❌ 예상치 못한 URL 형식: $publicUrl');
      return;
    }

    // 예: publicUrl = .../course_set_image/course_set/12345.jpg
    // filePath = course_set/12345.jpg
    final String filePath = publicUrl.substring(baseUrl.length);

    debugPrint('🧹 Storage 삭제 시도: bucket=course_set_image, path=$filePath');

    try {
      final res = await SupabaseManager.shared.supabase.storage
          .from('course_set_image')
          .remove([filePath]);
      debugPrint('🧹 Storage 삭제 결과: $res');
    } catch (e, st) {
      debugPrint('❌ Storage 삭제 중 오류: $e\n$st');
    }
  }

  /// ✅ 세트 수정 저장 (이미지 삭제 + 업데이트 모두 처리)
  Future<void> _saveEdit() async {
    List<int?> setIds = [];

    for (int i = 0; i < _courseSetDataList.length; i++) {
      final set = _courseSetDataList[i];
      final oldId = i < _existingSetIds.length ? _existingSetIds[i] : null;

      debugPrint(
        "🧩 set index=$i, oldId=$oldId, existingSetIds=$_existingSetIds",
      );

      // -------------------------------
      // 0) 원래 DB 이미지 vs 현재 유지 중 이미지 비교
      //    → 삭제해야 할 URL 찾기 (for_update_url 개념)
      // -------------------------------
      final List<String> original = i < _originalImageUrls.length
          ? _originalImageUrls[i]
          : <String>[];
      final List<String> currentExisting = List<String>.from(
        set.existingImages,
      );

      final deletedUrls = original
          .where((url) => !currentExisting.contains(url))
          .toList();

      debugPrint("🧹 삭제 대상 URL(original - current) = $deletedUrls");

      // Storage에서 삭제 대상만 제거
      for (final url in deletedUrls) {
        await _deleteImageFromStorage(url);
      }

      // -------------------------------
      // 1) 새 이미지 업로드
      // -------------------------------
      List<String> uploaded = [];
      for (final f in set.images) {
        final uploadedUrl = await SupabaseManager.shared.uploadCourseSetImage(
          f,
        );
        if (uploadedUrl != null) {
          uploaded.add(uploadedUrl);
        }
      }

      // -------------------------------
      // 2) 최종 이미지 리스트 구성
      //    - 남겨둔 기존 이미지 + 새로 업로드한 이미지
      // -------------------------------
      final List<String> finalImages = [
        ...currentExisting, // 사용자가 안 지운 기존 URL들
        ...uploaded, // 새로 추가한 이미지 URL들
      ];

      String? img1 = finalImages.isNotEmpty ? finalImages[0] : null;
      String? img2 = finalImages.length > 1 ? finalImages[1] : null;
      String? img3 = finalImages.length > 2 ? finalImages[2] : null;

      // -------------------------------
      // 3) 기존 세트 업데이트 또는 새 세트 생성
      // -------------------------------
      if (oldId != null) {
        final response = await SupabaseManager.shared.supabase
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
            .eq('id', oldId)
            .select();

        debugPrint("✅ UPDATED id=$oldId rows=${response.length}");
        setIds.add(oldId);
      } else {
        final newId = await SupabaseManager.shared.insertCourseSet(
          img1: img1,
          img2: img2,
          img3: img3,
          address: set.query ?? '',
          lat: set.lat!,
          lng: set.lng!,
          gu: set.gu,
          tagId: set.tagId,
          description: set.description,
        );
        setIds.add(newId);
      }
    }

    // -------------------------------
    // 4) 코스 메인 테이블 업데이트
    // -------------------------------
    await SupabaseManager.shared.supabase
        .from('courses')
        .update({
          'title': _titleController.text,
          'set_01': setIds.length > 0 ? setIds[0] : null,
          'set_02': setIds.length > 1 ? setIds[1] : null,
          'set_03': setIds.length > 2 ? setIds[2] : null,
          'set_04': setIds.length > 3 ? setIds[3] : null,
          'set_05': setIds.length > 4 ? setIds[4] : null,
        })
        .eq('id', widget.courseId);

    // -------------------------------
    // 5) 삭제된 세트 DB 삭제 (해당 세트 전체 제거)
    // -------------------------------
    for (final deletedId in _deletedSetIds) {
      await SupabaseManager.shared.supabase
          .from('course_sets')
          .delete()
          .eq('id', deletedId);
    }

    if (mounted) context.pop(true);
  }

  /// ✅ 뒤로가기/취소 팝업
  Future<bool> _onWillPop() async {
    final ok =
        await showDialog<bool>(
          context: context,
          barrierDismissible: true,
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
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 42,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "코스 수정을 취소하시겠습니까?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "수정 전 상태로 돌아갑니다.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.black54),
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

    if (ok) context.pop(false);
    return false; // 뒤로가기 막고 팝업에서 처리
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // ✅ 핸드폰 뒤로가기 제어
      child: Scaffold(
        appBar: AppBar(
          title: const Text("코스 수정"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              // ✅ AppBar 뒤로가기 버튼 눌러도 동일 팝업 표시
              await _onWillPop();
            },
          ),
          actions: [
            TextButton(
              onPressed: _saveEdit,
              child: const Text("수정완료", style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(hintText: '코스 제목'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  key: _mapKey,
                  height: 300,
                  child: NaverMap(
                    onMapReady: (c) async {
                      _mapController = c;
                      await _initMarkersForExistingSets();
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ..._courseSetDataList.asMap().entries.map((entry) {
                  final i = entry.key;
                  final set = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: WriteCourseSet(
                      key: ValueKey("edit_set_$i"),
                      tagList: tagList,
                      highlight: _highlightList[i],
                      existingImageUrls: set.existingImages,
                      initialQuery: set.query,
                      initialDescription: set.description,
                      initialTagId: set.tagId,
                      onTagChanged: (tag) => set.tagId = tag.id,
                      onScrollToTop: (offsetY) {
                        _scrollController.animateTo(
                          offsetY - 20,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      onSearchRequested: (query) =>
                          _handleLocationSelected(i, query),
                      onShowMapRequested: _scrollToMap,
                      onLocationSaved: (lat, lng) {
                        set.lat = lat;
                        set.lng = lng;
                      },
                      // ✅ 새로 추가된 로컬 이미지 파일 리스트
                      onImagesChanged: (imgs) {
                        set.images = imgs;
                      },
                      // ✅ 기존 URL 리스트가 바뀔 때마다 현재 상태를 세트에 반영
                      //    (네가 말한 for_update_url 역할)
                      onExistingImagesChanged: (list) {
                        set.existingImages = list;
                      },
                      onDescriptionChanged: (txt) => set.description = txt,
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _addNewSet,
                      child: const Text("세트 추가"),
                    ),
                    const SizedBox(width: 12),
                    if (_courseSetDataList.length >= 3)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        onPressed: () async {
                          final lastIndex = _courseSetDataList.length - 1;
                          final set = _courseSetDataList[lastIndex];

                          // 🔥 세트 통째로 삭제할 때: 그 세트가 들고 있던 이미지 모두 Storage 제거
                          for (final url in _originalImageUrls[lastIndex]) {
                            await _deleteImageFromStorage(url);
                          }

                          await _removeMarkerIfExists(lastIndex);

                          setState(() {
                            if (_existingSetIds.length > lastIndex) {
                              final deletedId = _existingSetIds[lastIndex];
                              _deletedSetIds.add(deletedId);
                              _existingSetIds.removeAt(lastIndex);
                            }
                            _courseSetDataList.removeLast();
                            _highlightList.removeLast();
                            _originalImageUrls.removeLast();
                          });
                        },
                        child: const Text("세트 삭제"),
                      ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
