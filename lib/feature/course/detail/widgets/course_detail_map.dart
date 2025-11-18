import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:of_course/feature/course/models/course_detail_models.dart';

class CourseDetailMap extends StatefulWidget {
  final CourseDetail courseDetail;
  final Map<String, GlobalKey> setCardKeys;
  final GlobalKey mapSectionKey;
  final Function(String) onMarkerTap;
  final CourseDetailMapController? controller;

  const CourseDetailMap({
    super.key,
    required this.courseDetail,
    required this.setCardKeys,
    required this.mapSectionKey,
    required this.onMarkerTap,
    this.controller,
  });

  @override
  State<CourseDetailMap> createState() => _CourseDetailMapState();
}

class CourseDetailMapController {
  _CourseDetailMapState? _state;

  void _attach(_CourseDetailMapState state) {
    _state = state;
  }

  void moveToMarker(String setId) {
    _state?.moveToMarker(setId);
  }
}

class _CourseDetailMapState extends State<CourseDetailMap> {
  NaverMapController? _mapController;
  final List<NMarker> _markers = [];
  final Map<String, NLatLng> _markerPositions = {};
  static const Color _mainColor = Color(0xFF003366);
  CourseDetailMapController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller?._attach(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mapController != null) {
        _initMarkers();
      }
    });
  }

  void _initMarkers() {
    if (widget.courseDetail.sets.isEmpty) return;

    _markers.clear();
    _markerPositions.clear();
    final List<NLatLng> points = [];

    int setNumber = 1;
    for (final set in widget.courseDetail.sets) {
      if (set.lat == 0.0 || set.lng == 0.0) continue;

      final pos = NLatLng(set.lat, set.lng);
      points.add(pos);

      final marker = NMarker(
        id: set.setId,
        position: pos,
        caption: NOverlayCaption(
          text: setNumber.toString(),
          textSize: 14,
        ),
      );

      marker.setOnTapListener((overlay) {
        widget.onMarkerTap(set.setId);
        moveToMarker(set.setId);
      });

      _markers.add(marker);
      _markerPositions[set.setId] = pos;
      setNumber++;
    }

    if (_mapController != null && points.isNotEmpty) {
      _mapController!.addOverlayAll(_markers.toSet());

      if (points.length >= 2) {
        final polylineOverlay = NPolylineOverlay(
          id: 'course_polyline_path',
          coords: points,
          color: _mainColor,
          width: 5,
        );
        _mapController!.addOverlay(polylineOverlay);
      }

      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;

      for (final p in points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }

      final bounds = NLatLngBounds(
        southWest: NLatLng(minLat, minLng),
        northEast: NLatLng(maxLat, maxLng),
      );

      _mapController!.updateCamera(
        NCameraUpdate.fitBounds(
          bounds,
          padding: const EdgeInsets.all(60),
        ),
      );
    }
  }

  void moveToMarker(String setId) {
    final set = widget.courseDetail.sets.firstWhere(
          (s) => s.setId == setId,
      orElse: () => widget.courseDetail.sets.first,
    );

    if (set.lat == 0.0 || set.lng == 0.0) return;
    if (_mapController == null) return;

    final target = NLatLng(set.lat, set.lng);

    final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
      target: target,
      zoom: 16.0,
    );

    _mapController!.updateCamera(cameraUpdate);
  }

  @override
  void didUpdateWidget(CourseDetailMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courseDetail.courseId != widget.courseDetail.courseId) {
      _initMarkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: widget.mapSectionKey,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              NaverMap(
                forceGesture: true,
                onMapReady: (controller) {
                  _mapController = controller;
                  _initMarkers();
                },
                options: const NaverMapViewOptions(
                  zoomGesturesEnable: true,
                  scrollGesturesEnable: true,
                  rotationGesturesEnable: true,
                  locationButtonEnable: false,
                  indoorEnable: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ZoomButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
          ),
        ],
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 22,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
