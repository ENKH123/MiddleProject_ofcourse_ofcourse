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

  Future<void> _removeMarkerIfExists(int index) async {
    final oldId = _markerIdBySet[index];
    if (oldId == null || _mapController == null) return;
    await _mapController!.deleteOverlay(
      NOverlayInfo(id: oldId, type: NOverlayType.marker),
    );
    _markerIdBySet.remove(index);
  }

  Future<void> _handleLocationSelected(int index, String query) async {
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

  void _addNewSet() {
    setState(() {
      _courseSetDataList.add(CourseSetData());
      _highlightList.add(false);
    });
  }

  Future<void> _saveEdit() async {
    List<int?> setIds = [];

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

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("코스 수정"),
        actions: [TextButton(onPressed: _saveEdit, child: const Text("수정완료"))],
      ),
      body: SingleChildScrollView(
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
              child: NaverMap(onMapReady: (c) => _mapController = c),
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
                  onLocationSaved: (lat, lng) {
                    set.lat = lat;
                    set.lng = lng;
                  },
                  onImagesChanged: (imgs) => set.images = imgs,
                  onDescriptionChanged: (txt) => set.description = txt,
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
                if (_courseSetDataList.length > 1)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () {
                      final lastIndex = _courseSetDataList.length - 1;
                      _removeMarkerIfExists(lastIndex);
                      setState(() {
                        _courseSetDataList.removeLast();
                        _highlightList.removeLast();
                        if (_existingSetIds.length > lastIndex) {
                          _existingSetIds.removeAt(lastIndex);
                        }
                      });
                    },
                    child: const Text("세트 삭제"),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
