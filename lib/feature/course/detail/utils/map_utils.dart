import 'dart:math' as math;

import 'package:flutter_naver_map/flutter_naver_map.dart';

class MapUtils {
  /// 두 좌표 간 거리 계산 (하버사인 공식, 미터 단위)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // 지구 반지름 (미터)
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * (math.pi / 180.0);

  /// 지도 탭 이벤트 처리 - 가장 가까운 마커 찾기
  static String? findClosestMarker(
    NLatLng tappedLocation,
    Map<String, NLatLng> markerPositions, {
    double maxTapDistanceMeters = 100.0,
  }) {
    if (markerPositions.isEmpty) return null;

    String? closestMarkerId;
    double minDistance = double.infinity;

    for (final entry in markerPositions.entries) {
      final markerId = entry.key;
      final markerPos = entry.value;
      final distance = calculateDistance(
        tappedLocation.latitude,
        tappedLocation.longitude,
        markerPos.latitude,
        markerPos.longitude,
      );

      if (distance < minDistance && distance < maxTapDistanceMeters) {
        minDistance = distance;
        closestMarkerId = markerId;
      }
    }

    return closestMarkerId;
  }
}

