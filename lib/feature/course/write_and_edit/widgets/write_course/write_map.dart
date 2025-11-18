import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class WriteMapView extends StatelessWidget {
  const WriteMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: NaverMap(
        options: const NaverMapViewOptions(
          initialCameraPosition: NCameraPosition(
            target: NLatLng(37.5665, 126.9780),
            zoom: 12,
          ),
        ),
      ),
    );
  }
}
