import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/tags_moedl.dart';
import 'package:of_course/feature/course/components/course_set.dart';

//  세트 데이터 모델

class CourseSetData {
  String? query;
  double? lat;
  double? lng;
  int? tagId;
  int? gu;
  List<File> images = [];
  String? description;

  CourseSetData();
}

//  코스 작성 페이지

class WriteCoursePage extends StatefulWidget {
  const WriteCoursePage({super.key});

  @override
  State<WriteCoursePage> createState() => _WriteCoursePageState();
}

class _WriteCoursePageState extends State<WriteCoursePage> {
  final ScrollController _scrollController = ScrollController();

  final List<WriteCourseSet> _sets = [];
  final List<CourseSetData> _courseSetDataList = [];
  final List<bool> _highlightList = []; //  흔들림 / 강조 상태 저장

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
    setState(() {
      for (int i = 0; i < 2; i++) _addNewSet();
    });
  }

  Future<void> _loadTags() async {
    tagList = await SupabaseManager.shared.getTags();
  }

  void _addNewSet() {
    final index = _courseSetDataList.length;

    setState(() {
      _courseSetDataList.add(CourseSetData());
      _highlightList.add(false);

      _sets.add(
        WriteCourseSet(
          tagList: tagList,
          highlight: _highlightList[index],
          onTagChanged: (tag) => _courseSetDataList[index].tagId = tag.id,
          onSearchRequested: (query) => _handleLocationSelected(index, query),
          onLocationSaved: (lat, lng) {
            _courseSetDataList[index].lat = lat;
            _courseSetDataList[index].lng = lng;
          },
          onImagesChanged: (imgs) => _courseSetDataList[index].images = imgs,
          onDescriptionChanged: (text) =>
              _courseSetDataList[index].description = text,
        ),
      );
    });
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
      index * 450.0,
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

  Future<String?> _getGuFromLatLng(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://maps.apigw.ntruss.com/map-reversegeocode/v2/gc?request=coordsToaddr&coords=$lng,$lat&sourcecrs=epsg:4326&orders=admcode,legalcode,addr,roadaddr&output=json',
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
      if (data['results'] == null || data['results'].isEmpty) return null;

      final region = data['results'][0]['region'];
      return "${region['area1']['name']} ${region['area2']['name']} ${region['area3']['name']}";
    } catch (_) {}
    return null;
  }

  Future<void> _handleLocationSelected(int index, String query) async {
    NLatLng? location = await _getLatLngFromAddress(query);
    location ??= await _getLatLngFromKakao(query);
    if (location == null) return;

    _courseSetDataList[index].query = query;
    _courseSetDataList[index].lat = location.latitude;
    _courseSetDataList[index].lng = location.longitude;

    final guName = await _getGuFromLatLng(
      location.latitude,
      location.longitude,
    );
    if (guName != null) {
      _courseSetDataList[index].gu = await SupabaseManager.shared
          .getGuIdFromName(guName);
    }

    final marker = NMarker(
      id: 'marker_$index',
      position: location,
      caption: NOverlayCaption(text: query),
    );

    _mapController?.addOverlay(marker);
    _mapController?.updateCamera(
      NCameraUpdate.scrollAndZoomTo(target: location, zoom: 15),
    );
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

  void _onUpload() {
    if (_validateBeforeUpload()) _saveCourse(true);
  }

  void _onTempSave() {
    if (_validateBeforeUpload()) _saveCourse(false);
  }

  Future<void> _saveCourse(bool isDone) async {
    List<int?> setIds = [];

    for (var set in _courseSetDataList) {
      if (set.lat == null || set.lng == null) continue;

      String? img1, img2, img3;
      if (set.images.isNotEmpty)
        img1 = await SupabaseManager.shared.uploadCourseSetImage(set.images[0]);
      if (set.images.length > 1)
        img2 = await SupabaseManager.shared.uploadCourseSetImage(set.images[1]);
      if (set.images.length > 2)
        img3 = await SupabaseManager.shared.uploadCourseSetImage(set.images[2]);

      final id = await SupabaseManager.shared.insertCourseSet(
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

      if (id != null) setIds.add(id);
    }

    await SupabaseManager.shared.supabase.from('courses').insert({
      'title': _titleController.text,
      'set_01': setIds.length > 0 ? setIds[0] : null,
      'set_02': setIds.length > 1 ? setIds[1] : null,
      'set_03': setIds.length > 2 ? setIds[2] : null,
      'set_04': setIds.length > 3 ? setIds[3] : null,
      'set_05': setIds.length > 4 ? setIds[4] : null,
      'is_done': isDone,
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(isDone ? "코스 저장 완료" : "임시 저장 완료")));

    context.push('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: _onTempSave, child: const Text("임시저장")),
                  TextButton(
                    onPressed: () => context.push('/home'),
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
                height: 300,
                child: NaverMap(onMapReady: (c) => _mapController = c),
              ),
              const SizedBox(height: 16),

              ..._sets.asMap().entries.map((entry) {
                int index = entry.key;
                WriteCourseSet setWidget = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: WriteCourseSet(
                    key: ValueKey(index),
                    tagList: tagList,
                    highlight: _highlightList[index],
                    onTagChanged: (tag) =>
                        _courseSetDataList[index].tagId = tag.id,
                    onSearchRequested: (query) =>
                        _handleLocationSelected(index, query),
                    onLocationSaved: (lat, lng) {
                      _courseSetDataList[index].lat = lat;
                      _courseSetDataList[index].lng = lng;
                    },
                    onImagesChanged: (imgs) =>
                        _courseSetDataList[index].images = imgs,
                    onDescriptionChanged: (text) =>
                        _courseSetDataList[index].description = text,
                  ),
                );
              }),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _addNewSet,
                    child: const Text("세트 추가"),
                  ),
                  const SizedBox(width: 12),
                  if (_sets.length > 2)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _sets.removeLast();
                          _courseSetDataList.removeLast();
                          _highlightList.removeLast();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      child: const Text("세트 삭제"),
                    ),
                ],
              ),

              const SizedBox(height: 24),
              ElevatedButton(onPressed: _onUpload, child: const Text("코스 업로드")),
            ],
          ),
        ),
      ),
    );
  }
}
