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

enum TagType {
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
extension TagTypeExtension on TagType {
  String get displayName {
    switch (this) {
      case TagType.all:
        return '전체';
      case TagType.Food:
        return '맛짐';
      case TagType.Cafe:
        return '카페';
      case TagType.Entertainment:
        return '오락';
      case TagType.Walk:
        return '산책';
      case TagType.Drive:
        return '드라이브';
      case TagType.Relaxed:
        return '느좋';
      case TagType.Museum:
        return '전시/박물관';
      case TagType.Activity:
        return '액티비티';
      case TagType.Movie:
        return '영화';
      case TagType.Book:
        return '도서';
      case TagType.Rest:
        return '휴식';
      case TagType.Sightseeing:
        return '관광';
      case TagType.Indoor:
        return '실내';
      case TagType.EscapeRoom:
        return '방탈출';
      case TagType.Drink:
        return '술한잔';
      case TagType.Popup:
        return '팝업';
    }
  }
}
