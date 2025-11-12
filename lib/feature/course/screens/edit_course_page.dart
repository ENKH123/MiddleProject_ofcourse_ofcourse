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
      final model = CourseSetData()
        ..query = s['query']
        ..lat = s['lat']
        ..lng = s['lng']
        ..gu = s['gu']
        ..tagId = s['tag_id']
        ..description = s['description']
        ..existingImages = List<String>.from(s['images']);

      _existingSetIds.add(s['id']);
      _courseSetDataList.add(model);
      _highlightList.add(false);
    }

    // 지도 생성 후 마커 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMarkersForExistingSets();
    });
  }

  /// ✅ 기존 세트 좌표 기반으로 마커 표시 및 줌 조정
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

    // 모든 마커가 보이도록 줌 조정
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

  /// ✅ 지도 스크롤 이동
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

  /// ✅ 주소 → 좌표 변환 (Naver, Kakao)
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

  /// ✅ 좌표 → 행정구 이름 변환
  Future<String?> _getGuFromLatLng(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://maps.apigw.ntruss.com/map-reversegeocode/v2/gc?request=coordsToaddr&coords=$lng,$lat&sourcecrs=epsg:4326&orders=admcode,legalcode,addr,roadaddr&output=json',
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
      final region = data['results'][0]['region'];
      return "${region['area1']['name']} ${region['area2']['name']} ${region['area3']['name']}";
    } catch (_) {}
    return null;
  }

  /// ✅ 마커 삭제
  Future<void> _removeMarkerIfExists(int index) async {
    final oldId = _markerIdBySet[index];
    if (oldId == null || _mapController == null) return;
    await _mapController!.deleteOverlay(
      NOverlayInfo(id: oldId, type: NOverlayType.marker),
    );
    _markerIdBySet.remove(index);
  }

  /// ✅ 검색 결과 선택 시 마커 추가
  Future<void> _handleLocationSelected(int index, String query) async {
    _scrollToMap();
    NLatLng? loc = await _getLatLngFromAddress(query);
    loc ??= await _getLatLngFromKakao(query);
    if (loc == null) return;

    final set = _courseSetDataList[index];
    set.query = query;
    set.lat = loc.latitude;
    set.lng = loc.longitude;

    final guName = await _getGuFromLatLng(loc.latitude, loc.longitude);
    if (guName != null) {
      set.gu = await SupabaseManager.shared.getGuIdFromName(guName);
    }

    await _removeMarkerIfExists(index);
    final id = "edit_marker_$index";
    await _mapController?.addOverlay(NMarker(id: id, position: loc));
    _markerIdBySet[index] = id;

    await _mapController?.updateCamera(
      NCameraUpdate.scrollAndZoomTo(target: loc, zoom: 15),
    );
  }

  /// ✅ 세트 추가
  void _addNewSet() {
    setState(() {
      _courseSetDataList.add(CourseSetData());
      _highlightList.add(false);
    });
  }

  /// ✅ 세트 수정 저장
  Future<void> _saveEdit() async {
    List<int?> setIds = [];

    // ✅ 1. 세트별 업데이트 or 새 세트 추가
    for (int i = 0; i < _courseSetDataList.length; i++) {
      final set = _courseSetDataList[i];
      final oldId = i < _existingSetIds.length ? _existingSetIds[i] : null;

      List<String?> uploaded = [];
      for (final f in set.images) {
        uploaded.add(await SupabaseManager.shared.uploadCourseSetImage(f));
      }

      String? img1 = uploaded.isNotEmpty
          ? uploaded[0]
          : (set.existingImages.isNotEmpty ? set.existingImages[0] : null);
      String? img2 = uploaded.length > 1
          ? uploaded[1]
          : (set.existingImages.length > 1 ? set.existingImages[1] : null);
      String? img3 = uploaded.length > 2
          ? uploaded[2]
          : (set.existingImages.length > 2 ? set.existingImages[2] : null);

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

    // ✅ 2. 코스 업데이트 먼저
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

    // ✅ 3. 코스 업데이트 후 삭제해야 참조 무결성 깨지지 않음
    for (final deletedId in _deletedSetIds) {
      await SupabaseManager.shared.supabase
          .from('course_sets')
          .delete()
          .eq('id', deletedId);
    }

    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("코스 수정"),
        actions: [TextButton(onPressed: _saveEdit, child: const Text("수정완료"))],
      ),
      body: SafeArea(
        // ✅ 시스템 하단바 피하기
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
                    onSearchRequested: (query) =>
                        _handleLocationSelected(i, query),
                    onShowMapRequested: _scrollToMap,
                    onLocationSaved: (lat, lng) {
                      set.lat = lat;
                      set.lng = lng;
                    },
                    onImagesChanged: (imgs) => set.images = imgs,
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
                  if (_courseSetDataList.length >= 3) // ✅ 3개 초과일 때만 삭제 버튼 표시
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      onPressed: () {
                        final lastIndex = _courseSetDataList.length - 1;
                        _removeMarkerIfExists(lastIndex);

                        setState(() {
                          if (_existingSetIds.length > lastIndex) {
                            final deletedId = _existingSetIds[lastIndex];
                            _deletedSetIds.add(deletedId);
                            _existingSetIds.removeAt(lastIndex);
                          }
                          _courseSetDataList.removeLast();
                          _highlightList.removeLast();
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
    );
  }
}
