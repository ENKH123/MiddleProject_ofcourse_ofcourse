import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:of_course/components/course_set.dart';

// 전체 페이지

class WriteCoursePage extends StatefulWidget {
  const WriteCoursePage({super.key});

  @override
  State<WriteCoursePage> createState() => _WriteCoursePageState();
}

class _WriteCoursePageState extends State<WriteCoursePage> {
  final List<Widget> _sets = [];
  File? _mainImage;
  final ImagePicker _picker = ImagePicker();
  NaverMapController? _mapController;

  //  네이버 지도 API 키
  static const _naverClientId = 'sr1eyuomlk';
  static const _naverClientSecret = 'XtMhndnqfc7MFpLU81jxfzvivP0LNJbSIu2wphec';

  //  카카오 REST API Key
  static const _kakaoRestKey = '05df8363e23a77cc74e7c20a667b6c7e';

  @override
  void initState() {
    super.initState();
    _sets.addAll([
      WriteCourseSet(onLocationSelected: _handleLocationSelected),
      WriteCourseSet(onLocationSelected: _handleLocationSelected),
    ]);
  }

  // 세트에서 전달받은 위치로 지도에 마커 표시
  Future<void> _handleLocationSelected(String query) async {
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

    final marker = NMarker(
      id: 'marker_${DateTime.now().millisecondsSinceEpoch}',
      position: location,
      caption: NOverlayCaption(text: query),
    );

    _mapController?.addOverlay(marker);
    _mapController?.updateCamera(
      NCameraUpdate.scrollAndZoomTo(target: location, zoom: 15),
    );
  }

  //  네이버 주소검색
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
          final lat = double.parse(first['y']);
          final lng = double.parse(first['x']);
          return NLatLng(lat, lng);
        }
      }
    } catch (e) {
      debugPrint('주소 변환 오류: $e');
    }
    return null;
  }

  // 카카오 키워드 검색
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
          final lat = double.parse(first['y']);
          final lng = double.parse(first['x']);
          return NLatLng(lat, lng);
        }
      }
    } catch (e) {
      debugPrint('카카오 장소 검색 오류: $e');
    }
    return null;
  }

  // 이미지 선택
  Future<void> _pickMainImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() => _mainImage = File(pickedFile.path));
    }
  }

  // 세트 추가 / 제거
  void _addSet() {
    setState(() {
      if (_sets.length < 5) {
        _sets.add(WriteCourseSet(onLocationSelected: _handleLocationSelected));
      }
    });
  }

  void _removeSet() {
    if (_sets.length > 2) {
      setState(() {
        _sets.removeLast();
      });
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
              // 상단 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: () {}, child: const Text("임시저장")),
                  TextButton(onPressed: () {}, child: const Text("취소")),
                ],
              ),
              const SizedBox(height: 8),

              // 제목 입력
              TextField(
                decoration: InputDecoration(
                  hintText: '제목을 입력해주세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 16),

              //  지도 표시
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 300,
                  child: NaverMap(
                    options: const NaverMapViewOptions(
                      initialCameraPosition: NCameraPosition(
                        target: NLatLng(37.5666, 126.9784),
                        zoom: 13,
                      ),
                    ),
                    onMapReady: (controller) {
                      _mapController = controller;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 세트 목록
              ..._sets.map(
                (set) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: set,
                ),
              ),

              // 세트 추가/삭제
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _addSet,
                    icon: const Icon(Icons.add),
                    label: const Text('세트 추가'),
                  ),
                  const SizedBox(width: 12),
                  if (_sets.length > 2)
                    ElevatedButton.icon(
                      onPressed: _removeSet,
                      icon: const Icon(Icons.remove),
                      label: const Text('세트 삭제'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 30),

              // 업로드 버튼
              Center(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('코스 업로드'),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
