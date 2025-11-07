import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/tags_moedl.dart';
import 'package:of_course/feature/course/components/course_set.dart';

// --------------------------------------
//  코스 작성 페이지
// --------------------------------------
class WriteCoursePage extends StatefulWidget {
  const WriteCoursePage({super.key});

  @override
  State<WriteCoursePage> createState() => _WriteCoursePageState();
}

//  세트 데이터 모델

class CourseSetData {
  String? query;
  double? lat;
  double? lng;
  int? tagId;

  CourseSetData({this.query, this.lat, this.lng, this.tagId});

  Map<String, dynamic> toJson() => {
    'query': query,
    'lat': lat,
    'lng': lng,
    'tag_id': tagId,
  };
}

// --------------------------------------
//  메인 페이지
// --------------------------------------
class _WriteCoursePageState extends State<WriteCoursePage> {
  final List<WriteCourseSet> _sets = [];
  final List<CourseSetData> _courseSetDataList = [];
  List<TagModel> tagList = [];

  File? _mainImage;
  final ImagePicker _picker = ImagePicker();
  NaverMapController? _mapController;

  //  API Key
  static const _naverClientId = 'sr1eyuomlk';
  static const _naverClientSecret = 'XtMhndnqfc7MFpLU81jxfzvivP0LNJbSIu2wphec';
  static const _kakaoRestKey = '05df8363e23a77cc74e7c20a667b6c7e';

  @override
  void initState() {
    super.initState();
    _loadTags();

    // 기본 세트 2개 생성
    for (int i = 0; i < 2; i++) {
      _addNewSet();
    }
  }

  Future<void> _loadTags() async {
    final list = await SupabaseManager.shared.getTags();
    setState(() {
      tagList = list;
    });
  }

  void _addNewSet() {
    final index = _courseSetDataList.length;

    _courseSetDataList.add(CourseSetData());

    _sets.add(
      WriteCourseSet(
        tagList: tagList,
        onTagChanged: (tag) {
          _courseSetDataList[index].tagId = tag.id;
        },
        onSearchRequested: (query) => _handleLocationSelected(index, query),
        onLocationSaved: (lat, lng) {
          _courseSetDataList[index].lat = lat;
          _courseSetDataList[index].lng = lng;
        },
      ),
    );

    setState(() {});
  }

  // 세트 제거
  void _removeSet() {
    if (_sets.length > 2) {
      setState(() {
        _sets.removeLast();
        _courseSetDataList.removeLast();
      });
    }
  }

  // 검색 처리
  Future<void> _handleLocationSelected(int index, String query) async {
    NLatLng? location = await _getLatLngFromAddress(query);
    location ??= await _getLatLngFromKakao(query);

    if (location == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('위치를 찾을 수 없습니다.')));
      }
      return;
    }

    _courseSetDataList[index].query = query;
    _courseSetDataList[index].lat = location.latitude;
    _courseSetDataList[index].lng = location.longitude;

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

  // 네이버 지오코딩 API
  Future<NLatLng?> _getLatLngFromAddress(String query) async {
    try {
      final encodedQuery = Uri.encodeQueryComponent(query);
      final url = Uri.parse(
        'https://maps.apigw.ntruss.com/map-geocode/v2/geocode?query=$encodedQuery',
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'x-ncp-apigw-api-key-id': _naverClientId,
          'x-ncp-apigw-api-key': _naverClientSecret,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if ((data['addresses'] as List).isNotEmpty) {
          final first = (data['addresses'] as List).first;
          return NLatLng(double.parse(first['y']), double.parse(first['x']));
        }
      }
    } catch (_) {}
    return null;
  }

  // 카카오 키워드 검색 API
  Future<NLatLng?> _getLatLngFromKakao(String query) async {
    try {
      final encodedQuery = Uri.encodeQueryComponent(query);
      final url = Uri.parse(
        'https://dapi.kakao.com/v2/local/search/keyword.json?query=$encodedQuery',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'KakaoAK $_kakaoRestKey'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final documents = data['documents'] as List;
        if (documents.isNotEmpty) {
          final first = documents.first;
          return NLatLng(double.parse(first['y']), double.parse(first['x']));
        }
      }
    } catch (_) {}
    return null;
  }

  // 메인 이미지 선택
  Future<void> _pickMainImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _mainImage = File(pickedFile.path));
    }
  }

  //  업로드 테스트
  void _onUpload() {
    debugPrint("========= 업로드 데이터 =========");
    for (var set in _courseSetDataList) {
      debugPrint(set.toJson().toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: '제목을 입력해주세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 지도
              SizedBox(
                height: 300,
                child: NaverMap(
                  onMapReady: (controller) => _mapController = controller,
                ),
              ),

              const SizedBox(height: 16),

              ..._sets.map(
                (set) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: set,
                ),
              ),

              Center(
                child: ElevatedButton(
                  onPressed: () => _addNewSet(),
                  child: const Text("세트 추가"),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: ElevatedButton(
                  onPressed: _onUpload,
                  child: const Text("코스 업로드"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
