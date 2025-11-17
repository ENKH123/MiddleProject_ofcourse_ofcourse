import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/tags_moedl.dart';

import '../components/course_set.dart';

class CourseSetData {
  String? query;
  double? lat;
  double? lng;
  int? tagId;
  int? gu;
  List<File> images = [];
  String? description;
  List<String> existingImages = []; // ✅ 현재 세트에 남아 있는 이미지 URL들

  CourseSetData();
}

class WriteCoursePage extends StatefulWidget {
  final int? continueCourseId;
  const WriteCoursePage({super.key, this.continueCourseId});

  @override
  State<WriteCoursePage> createState() => _WriteCoursePageState();
}

class _WriteCoursePageState extends State<WriteCoursePage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _mapKey = GlobalKey(debugLabel: "write_map_key");

  final List<CourseSetData> _courseSetDataList = [];
  final List<bool> _highlightList = [];

  final Map<int, String> _markerIdBySet = {};

  final List<int> _existingSetIds = [];
  final List<int> _deletedSetIds = [];

  /// ✅ continue 모드에서 각 세트별 "처음 DB에서 가져온 이미지 URL 리스트" 저장용
  final List<List<String>> _originalImageUrls = [];

  List<TagModel> tagList = [];
  final TextEditingController _titleController = TextEditingController();
  NaverMapController? _mapController;

  static const _naverClientId = 'sr1eyuomlk';
  static const _naverClientSecret = 'XtMhndnqfc7MFpLU81jxfzvivP0LNJbSIu2wphec';
  static const _kakaoRestKey = '05df8363e23a77cc74e7c20a667b6c7e';

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    await _loadTags();

    // continue 모드
    if (widget.continueCourseId != null) {
      await _loadContinueCourse(widget.continueCourseId!);
    }
    // 새 코스 작성 모드
    else {
      setState(() {
        for (int i = 0; i < 2; i++) {
          _courseSetDataList.add(CourseSetData());
          _highlightList.add(false);
          _originalImageUrls.add([]); // ✅ 새 세트는 원본 이미지 없음
        }
      });
    }
  }

  Future<void> _loadTags() async {
    tagList = await SupabaseManager.shared.getTags();
  }

  Future<void> _loadContinueCourse(int courseId) async {
    final data = await SupabaseManager.shared.getCourseDetailForContinue(
      courseId,
    );
    if (data == null) return;

    _titleController.text = data['title'];

    // 기존 세트 불러오기
    for (var s in data['sets']) {
      final images = List<String>.from(s['images'] ?? []);

      final model = CourseSetData()
        ..query = s['query']
        ..lat = s['lat']
        ..lng = s['lng']
        ..gu = s['gu']
        ..tagId = s['tag_id']
        ..description = s['description']
        ..existingImages = List<String>.from(images); // ✅ 현재 유지중인 URL 리스트

      _existingSetIds.add(s['id']);
      _courseSetDataList.add(model);
      _highlightList.add(false);

      // ✅ "처음 DB에서 가져온 원본 이미지 리스트" 저장
      _originalImageUrls.add(List<String>.from(images));
    }

    // 최소 2개 세트 보장
    while (_courseSetDataList.length < 2) {
      _courseSetDataList.add(CourseSetData());
      _highlightList.add(false);
      _originalImageUrls.add([]); // 원본 없음
    }

    // 지도 마커 생성
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initMarkersForExistingSets();
    });

    setState(() {});
  }

  Future<void> _initMarkersForExistingSets() async {
    if (_mapController == null) return;

    List<NLatLng> positions = [];

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

      await _mapController!.updateCamera(
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

  Future<bool> _showConfirmDialog(String title) async {
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

  void _highlightSet(int index) {
    setState(() => _highlightList[index] = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _highlightList[index] = false);
    });
  }

  void _scrollToSet(int index) {
    _scrollController.animateTo(
      index * 450,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _validateBeforeUpload() {
    for (int i = 0; i < _courseSetDataList.length; i++) {
      final set = _courseSetDataList[i];

      if (set.lat == null || set.lng == null) {
        _scrollToSet(i);
        _highlightSet(i);
        _showMessage("세트 ${i + 1}: 위치 검색을 완료해주세요.");
        return false;
      }

      if (set.description == null || set.description!.trim().isEmpty) {
        _scrollToSet(i);
        _highlightSet(i);
        _showMessage("세트 ${i + 1}: 내용을 입력해주세요.");
        return false;
      }

      if (set.tagId == null) {
        _scrollToSet(i);
        _highlightSet(i);
        _showMessage("세트 ${i + 1}: 태그를 선택해주세요.");
        return false;
      }
    }
    return true;
  }

  Future<void> _removeMarkerIfExists(int setIndex) async {
    final oldId = _markerIdBySet[setIndex];
    if (oldId == null || _mapController == null) return;

    final info = NOverlayInfo(type: NOverlayType.marker, id: oldId);
    await _mapController!.deleteOverlay(info);
    _markerIdBySet.remove(setIndex);
  }

  /// ✅ Storage에서 public URL 기준으로 삭제 (URL 파싱 방식)
  Future<void> _deleteImageFromStorage(String publicUrl) async {
    if (publicUrl == "null" || publicUrl.isEmpty) return;

    try {
      final uri = Uri.parse(publicUrl);
      final segments = uri.pathSegments;

      // .../public/<bucket>/<objectPath>
      final publicIndex = segments.indexOf('public');
      if (publicIndex == -1 || publicIndex + 2 >= segments.length) {
        debugPrint('❌ URL 파싱 실패: $publicUrl');
        return;
      }

      final bucket = segments[publicIndex + 1]; // course_set_image
      final objectPath = segments
          .sublist(publicIndex + 2)
          .join('/'); // course_set/xxx.jpg

      debugPrint('🧹 Storage 삭제 시도: bucket=$bucket, path=$objectPath');

      final res = await SupabaseManager.shared.supabase.storage
          .from(bucket)
          .remove([objectPath]);

      debugPrint('🧹 Storage 삭제 결과: $res'); // [] 나오면 정상 삭제
    } catch (e, st) {
      debugPrint('❌ Storage 삭제 오류: $e\n$st');
    }
  }

  Future<void> _deleteSet(int index) async {
    await _removeMarkerIfExists(index);

    // ✅ 이 세트가 가진 원본 이미지도 모두 스토리지에서 삭제
    if (index < _originalImageUrls.length) {
      for (final url in _originalImageUrls[index]) {
        await _deleteImageFromStorage(url);
      }
      _originalImageUrls.removeAt(index);
    }

    if (index < _existingSetIds.length) {
      _deletedSetIds.add(_existingSetIds[index]);
      _existingSetIds.removeAt(index);
    }

    setState(() {
      _courseSetDataList.removeAt(index);
      _highlightList.removeAt(index);
    });
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

  Future<void> _handleLocationSelected(int index, String query) async {
    NLatLng? location = await _getLatLngFromAddress(query);
    location ??= await _getLatLngFromKakao(query);

    if (location == null) {
      _showMessage("위치를 찾을 수 없어요.");
      return;
    }

    final set = _courseSetDataList[index];

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

    await _mapController?.addOverlay(marker);
    _markerIdBySet[index] = markerId;

    await _mapController?.updateCamera(
      NCameraUpdate.scrollAndZoomTo(target: location, zoom: 15),
    );
  }

  Future<void> _onTempSave() async {
    final ok = await _showConfirmDialog("임시저장하시겠습니까?");
    if (!ok) return;

    if (widget.continueCourseId != null) {
      await _continuesaveEdit(false);
    } else {
      await _saveNew(false);
    }
  }

  Future<void> _onUpload() async {
    if (!_validateBeforeUpload()) return;

    if (widget.continueCourseId != null) {
      await _continuesaveEdit(true);
    } else {
      await _saveNew(true);
    }
  }

  Future<void> _saveNew(bool isDone) async {
    final userID = await SupabaseManager.shared.getMyUserRowId();

    List<int?> setIds = [];

    for (final set in _courseSetDataList) {
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
      'title': _titleController.text,
      'user_id': userID,
      'set_01': setIds.length > 0 ? setIds[0] : null,
      'set_02': setIds.length > 1 ? setIds[1] : null,
      'set_03': setIds.length > 2 ? setIds[2] : null,
      'set_04': setIds.length > 3 ? setIds[3] : null,
      'set_05': setIds.length > 4 ? setIds[4] : null,
      'is_done': isDone,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(isDone ? "코스 업로드 완료" : "임시 저장 완료")));

    context.push('/home');
  }

  /// ✅ continue 모드: 원본 vs 현재(existingImages) 비교 후 삭제 + 최종 이미지 구성
  Future<void> _continuesaveEdit(bool isDone) async {
    if (widget.continueCourseId == null) return;

    List<int?> setIds = [];

    for (int i = 0; i < _courseSetDataList.length; i++) {
      final set = _courseSetDataList[i];
      final oldId = i < _existingSetIds.length ? _existingSetIds[i] : null;

      // ---------------------------------------------------------
      // 0) 원본 vs 현재 existing 비교 → 삭제할 이미지 찾기
      // ---------------------------------------------------------
      final List<String> original = i < _originalImageUrls.length
          ? _originalImageUrls[i]
          : <String>[];

      final List<String> currentExisting = List<String>.from(
        set.existingImages,
      );

      final deletedUrls = original
          .where((url) => !currentExisting.contains(url))
          .toList();

      debugPrint("🧹 [continue] 세트 $i 삭제할 이미지 = $deletedUrls");

      for (final url in deletedUrls) {
        await _deleteImageFromStorage(url);
      }

      // ---------------------------------------------------------
      // 1) 새 이미지 업로드
      // ---------------------------------------------------------
      List<String> uploaded = [];
      for (final f in set.images) {
        final u = await SupabaseManager.shared.uploadCourseSetImage(f);
        if (u != null) uploaded.add(u);
      }

      // ---------------------------------------------------------
      // 2) 최종 이미지 리스트 구성
      // ---------------------------------------------------------
      final List<String> finalImages = [...currentExisting, ...uploaded];

      String? img1 = finalImages.isNotEmpty ? finalImages[0] : null;
      String? img2 = finalImages.length > 1 ? finalImages[1] : null;
      String? img3 = finalImages.length > 2 ? finalImages[2] : null;

      // ---------------------------------------------------------
      // 3) 기존 세트면 update, 신규면 insert
      // ---------------------------------------------------------
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

    // ---------------------------------------------------------
    // 4) 완전히 삭제된 세트 DB삭제
    // ---------------------------------------------------------
    for (final del in _deletedSetIds) {
      await SupabaseManager.shared.supabase
          .from('course_sets')
          .delete()
          .eq('id', del);
    }

    // ---------------------------------------------------------
    // 5) courses 테이블 업데이트
    // ---------------------------------------------------------
    await SupabaseManager.shared.supabase
        .from('courses')
        .update({
          'title': _titleController.text,
          'set_01': setIds.length > 0 ? setIds[0] : null,
          'set_02': setIds.length > 1 ? setIds[1] : null,
          'set_03': setIds.length > 2 ? setIds[2] : null,
          'set_04': setIds.length > 3 ? setIds[3] : null,
          'set_05': setIds.length > 4 ? setIds[4] : null,
          'is_done': isDone,
        })
        .eq('id', widget.continueCourseId!);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(isDone ? "코스 업로드 완료" : "임시 저장 완료")));

    context.push('/home');
  }

  void _scrollToMap() {
    final ctx = _mapKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final ok =
            await showDialog<bool>(
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
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 42,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "코스 작성을 취소하시겠습니까?",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "저장되지 않은 내용이 사라집니다.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
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

        if (ok) {
          // 🔥 뒤로가기 팝 대신 home으로 이동
          context.pushReplacement('/home');
          return false; // 앱이 종료되지 않도록 pop 막기
        }

        return false; // 취소 눌러도 pop 하지 않음
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _onTempSave,
                      child: const Text("임시저장"),
                    ),
                    TextButton(
                      onPressed: () async {
                        final ok = await _showConfirmDialog(
                          "작성 중인 내용을 취소하시겠습니까?",
                        );
                        if (ok) context.push('/home');
                      },
                      child: const Text("취소"),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: '코스 제목',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  key: _mapKey,
                  height: 300,
                  child: NaverMap(
                    onMapReady: (c) => _mapController = c,
                    options: const NaverMapViewOptions(
                      initialCameraPosition: NCameraPosition(
                        target: NLatLng(37.5665, 126.9780),
                        zoom: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                ..._courseSetDataList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final set = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: WriteCourseSet(
                      key: ValueKey("write_set_$index"),
                      tagList: tagList,
                      highlight: _highlightList[index],

                      initialQuery: set.query,
                      initialDescription: set.description,
                      initialTagId: set.tagId,
                      existingImageUrls: set.existingImages,

                      onTagChanged: (tag) => set.tagId = tag.id,
                      onDescriptionChanged: (txt) => set.description = txt,
                      onImagesChanged: (imgs) => set.images = imgs,
                      onExistingImagesChanged: (list) =>
                          set.existingImages = list,

                      onSearchRequested: (q) =>
                          _handleLocationSelected(index, q),
                      onLocationSaved: (lat, lng) {
                        set.lat = lat;
                        set.lng = lng;
                      },
                      onShowMapRequested: _scrollToMap,
                      onScrollToTop: (offsetY) {
                        _scrollController.animateTo(
                          offsetY - 20, // 약간 여유 공간
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      },
                    ),
                  );
                }),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _courseSetDataList.add(CourseSetData());
                          _highlightList.add(false);
                          _originalImageUrls.add([]); // ✅ 새 세트는 원본 이미지 없음
                        });
                      },
                      child: const Text("세트 추가"),
                    ),

                    const SizedBox(width: 12),

                    if (_courseSetDataList.length > 2)
                      ElevatedButton(
                        onPressed: () {
                          _deleteSet(_courseSetDataList.length - 1);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        child: const Text("세트 삭제"),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _onUpload,
                  child: const Text("코스 업로드"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
