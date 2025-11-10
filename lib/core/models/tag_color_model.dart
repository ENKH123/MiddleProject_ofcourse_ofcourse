/// 태그 색상 모델
class TagColorModel {
  /// 태그 이름
  final String tagName;

  /// 태그 색상 (16진수 코드)
  final String colorHex;

  TagColorModel({
    required this.tagName,
    required this.colorHex,
  });

  /// Color 객체로 변환 (Flutter Color)
  int get colorValue {
    return int.parse(colorHex.replaceFirst('#', ''), radix: 16) + 0xFF000000;
  }

  /// 태그 이름으로 색상 찾기
  static String? getColorHex(String tagName) {
    return _tagColors[tagName];
  }

  /// 모든 태그 색상 맵
  static final Map<String, String> _tagColors = {
    '맛집': '#FFDDDD',
    '영화': '#FDDDFF',
    '카페': '#FFFFDD',
    '도서': '#FFE4B8',
    '오락': '#DDFFFF',
    '휴식': '#DDECFF',
    '산책': '#DDFFDD',
    '관광': '#DDFFEE',
    '드라이브': '#DCDADA',
    '실내': '#EEDDFF',
    '느좋': '#E5DDFF',
    '방탈출': '#FFBCBD',
    '전시/박물관': '#DDF6FF',
    '술 한잔': '#FDC4FF',
    '액티비티': '#D7FF9A',
    '팝업': '#A6FCEF',
  };

  /// 모든 태그 색상 목록
  static List<TagColorModel> get allTagColors {
    return _tagColors.entries
        .map((entry) => TagColorModel(
      tagName: entry.key,
      colorHex: entry.value,
    ))
        .toList();
  }

  /// JSON에서 생성
  factory TagColorModel.fromJson(Map<String, dynamic> json) {
    return TagColorModel(
      tagName: json['tagName'] as String,
      colorHex: json['colorHex'] as String,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'tagName': tagName,
      'colorHex': colorHex,
    };
  }
}

