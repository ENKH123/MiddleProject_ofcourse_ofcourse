enum SeoulDistrict { gangnam, gangdong, gangbuk, gangseo, gwanak, gwangjin }

extension SeoulDistrictExtension on SeoulDistrict {
  String get displayName {
    switch (this) {
      case SeoulDistrict.gangnam:
        return '강남구';
      case SeoulDistrict.gangdong:
        return '강동구';
      case SeoulDistrict.gangbuk:
        return '강북구';
      case SeoulDistrict.gangseo:
        return '강서구';
      case SeoulDistrict.gwanak:
        return '관악구';
      case SeoulDistrict.gwangjin:
        return '광진구';
    }
  }
}

enum ToggleButtonType {
  all,
  Food,
  Cafe,
  Entertainment,
  Walk,
  Drive,
  Relaxed,
  Museum,
  Activity,
  Movie,
  Book,
  Rest,
  Sightseeing,
  Indoor,
  EscapeRoom,
  Drink,
  Popup,
}

// ✅ Enum에 표시용 이름 매핑 (한글)
extension ToggleButtonTypeExtension on ToggleButtonType {
  String get displayName {
    switch (this) {
      case ToggleButtonType.all:
        return '전체';
      case ToggleButtonType.Food:
        return '맛짐';
      case ToggleButtonType.Cafe:
        return '카페';
      case ToggleButtonType.Entertainment:
        return '오락';
      case ToggleButtonType.Walk:
        return '산책';
      case ToggleButtonType.Drive:
        return '드라이브';
      case ToggleButtonType.Relaxed:
        return '느좋';
      case ToggleButtonType.Museum:
        return '전시/박물관';
      case ToggleButtonType.Activity:
        return '액티비티';
      case ToggleButtonType.Movie:
        return '영화';
      case ToggleButtonType.Book:
        return '도서';
      case ToggleButtonType.Rest:
        return '휴식';
      case ToggleButtonType.Sightseeing:
        return '관광';
      case ToggleButtonType.Indoor:
        return '실내';
      case ToggleButtonType.EscapeRoom:
        return '방탈출';
      case ToggleButtonType.Drink:
        return '술한잔';
      case ToggleButtonType.Popup:
        return '팝업';
    }
  }
}
