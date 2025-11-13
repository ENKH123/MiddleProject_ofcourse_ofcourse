/// 추천 알고리즘 JSON 응답을 자연스러운 한국어 문장으로 변환하는 유틸리티
class RecommendationParser {
  /// 추천 데이터에서 자연스러운 한국어 설명 문장 생성
  /// 
  /// [recommendation] 예시:
  /// {
  ///   "similarity_percent": 100,
  ///   "matched_tags": [{ "id": 9, "name": "영화" }],
  ///   "matched_gus": [{ "id": 24, "name": "중구" }]
  /// }
  static String generateRecommendationReason(Map<String, dynamic> recommendation) {
    final similarityPercent = recommendation['similarity_percent'] as int? ?? 0;
    final matchedTags = recommendation['matched_tags'] as List<dynamic>? ?? [];
    final matchedGus = recommendation['matched_gus'] as List<dynamic>? ?? [];

    // 1. 유사도를 첫 문장에 포함
    final StringBuffer reason = StringBuffer();
    reason.write('이 코스는 내 취향과 유사도 $similarityPercent%');

    // 2. matched_tags와 matched_gus 처리
    final tagNames = matchedTags
        .map((tag) => tag['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    final guNames = matchedGus
        .map((gu) => gu['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    final hasTags = tagNames.isNotEmpty;
    final hasGus = guNames.isNotEmpty;

    if (hasTags && hasGus) {
      // 4. 둘 다 있을 경우 자연스럽게 연결
      reason.write('. ');
      reason.write(_formatTags(tagNames));
      reason.write(', ');
      reason.write(_formatGus(guNames));
      reason.write('에서 자주 놀아서 추천했어요.');
    } else if (hasTags) {
      // 태그만 있을 경우
      reason.write('. ');
      reason.write(_formatTags(tagNames));
      reason.write(' 추천했어요.');
    } else if (hasGus) {
      // 지역만 있을 경우
      reason.write('. ');
      reason.write(_formatGus(guNames));
      reason.write('에서 자주 놀아서 추천했어요.');
    } else {
      // 5. 둘 다 없으면 최근 좋아요한 코스들과 구성이 비슷하다고 설명
      reason.write('. 최근 좋아요한 코스들과 구성이 비슷해서 추천했어요.');
    }

    return reason.toString();
  }

  /// 태그 목록을 자연스러운 한국어 문장으로 변환
  static String _formatTags(List<String> tagNames) {
    if (tagNames.isEmpty) return '';
    
    if (tagNames.length == 1) {
      return '최근에 ${tagNames[0]} 태그 코스를 자주 좋아했고';
    } else if (tagNames.length == 2) {
      return '최근에 ${tagNames[0]}, ${tagNames[1]} 태그 코스를 자주 좋아했고';
    } else {
      final lastTag = tagNames.last;
      final otherTags = tagNames.sublist(0, tagNames.length - 1);
      return '최근에 ${otherTags.join(', ')}, $lastTag 태그 코스를 자주 좋아했고';
    }
  }

  /// 지역 목록을 자연스러운 한국어 문장으로 변환
  static String _formatGus(List<String> guNames) {
    if (guNames.isEmpty) return '';
    
    if (guNames.length == 1) {
      return '${guNames[0]}';
    } else if (guNames.length == 2) {
      return '${guNames[0]}, ${guNames[1]}';
    } else {
      final lastGu = guNames.last;
      final otherGus = guNames.sublist(0, guNames.length - 1);
      return '${otherGus.join(', ')}, $lastGu';
    }
  }

  /// 전체 추천 응답에서 첫 번째 추천 코스의 정보 추출
  /// 
  /// [response] 예시:
  /// {
  ///   "summary": {...},
  ///   "recommendations": [
  ///     {
  ///       "course_id": 123,
  ///       "similarity_percent": 100,
  ///       "matched_tags": [...],
  ///       "matched_gus": [...]
  ///     }
  ///   ]
  /// }
  static Map<String, dynamic>? parseFirstRecommendation(Map<String, dynamic> response) {
    final recommendations = response['recommendations'] as List<dynamic>?;
    if (recommendations == null || recommendations.isEmpty) {
      return null;
    }

    final firstRecommendation = recommendations[0] as Map<String, dynamic>;
    
    // 코스 ID 추출: course 객체 안에 id가 있음
    int? courseId;
    
    // course 객체에서 id 추출
    final course = firstRecommendation['course'] as Map<String, dynamic>?;
    if (course != null) {
      final courseIdValue = course['id'];
      if (courseIdValue is int) {
        courseId = courseIdValue;
      } else if (courseIdValue is String) {
        courseId = int.tryParse(courseIdValue);
      } else if (courseIdValue != null) {
        courseId = int.tryParse(courseIdValue.toString());
      }
    }
    
    // course 객체가 없거나 id를 찾지 못한 경우, 직접 필드에서 시도
    if (courseId == null) {
      final possibleKeys = ['course_id', 'courseId', 'id'];
      for (final key in possibleKeys) {
        if (firstRecommendation.containsKey(key)) {
          final value = firstRecommendation[key];
          if (value is int) {
            courseId = value;
            break;
          } else if (value is String) {
            courseId = int.tryParse(value);
            if (courseId != null) break;
          } else if (value != null) {
            courseId = int.tryParse(value.toString());
            if (courseId != null) break;
          }
        }
      }
    }
    
    final reason = generateRecommendationReason(firstRecommendation);

    return {
      'courseId': courseId,
      'reason': reason,
    };
  }
}

