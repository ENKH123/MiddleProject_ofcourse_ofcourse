import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/edit_course_view_model.dart';

class EditMapView extends StatefulWidget {
  const EditMapView({super.key});

  @override
  State<EditMapView> createState() => _EditMapViewState();
}

class _EditMapViewState extends State<EditMapView> {
  NaverMapController? _controller;
  final Map<int, String> _markerIdBySet = {};

  Future<void> _addMarker(
    int index,
    double lat,
    double lng,
    String label,
  ) async {
    if (_controller == null) return;

    await _removeMarker(index);

    final id = "edit_marker_$index";
    final marker = NMarker(
      id: id,
      position: NLatLng(lat, lng),
      caption: NOverlayCaption(text: label),
    );

    await _controller!.addOverlay(marker);
    _markerIdBySet[index] = id;
  }

  Future<void> _removeMarker(int index) async {
    if (_controller == null) return;

    final id = _markerIdBySet[index];
    if (id != null) {
      await _controller!.deleteOverlay(
        NOverlayInfo(type: NOverlayType.marker, id: id),
      );
      _markerIdBySet.remove(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditCourseViewModel>();

    return SizedBox(
      height: 300,
      child: NaverMap(
        onMapReady: (c) {
          _controller = c;

          for (int i = 0; i < vm.sets.length; i++) {
            final s = vm.sets[i];
            if (s.lat != null && s.lng != null) {
              _addMarker(i, s.lat!, s.lng!, s.query ?? "위치");
            }
          }
        },
      ),
    );
  }
}
