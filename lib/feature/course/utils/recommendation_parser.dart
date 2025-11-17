
class RecommendationParser {

  static String generateRecommendationReason(Map<String, dynamic> recommendation) {
    final similarityPercent = recommendation['similarity_percent'] as int? ?? 0;
    final matchedTags = recommendation['matched_tags'] as List<dynamic>? ?? [];
    final matchedGus = recommendation['matched_gus'] as List<dynamic>? ?? [];

    final StringBuffer reason = StringBuffer();
    reason.write('이 코스는 내 취향과 유사도 $similarityPercent%');

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
      reason.write('. ');
      reason.write(_formatTags(tagNames));
      reason.write(', ');
      reason.write(_formatGus(guNames));
      reason.write('에서 자주 놀아서 추천했어요.');
    } else if (hasTags) {
      reason.write('. ');
      reason.write(_formatTags(tagNames));
      reason.write(' 추천했어요.');
    } else if (hasGus) {
      reason.write('. ');
      reason.write(_formatGus(guNames));
      reason.write('에서 자주 놀아서 추천했어요.');
    } else {
      reason.write('. 최근 좋아요한 코스들과 구성이 비슷해서 추천했어요.');
    }

    return reason.toString();
  }

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

  static Map<String, dynamic>? parseFirstRecommendation(Map<String, dynamic> response) {
    final recommendations = response['recommendations'] as List<dynamic>?;
    if (recommendations == null || recommendations.isEmpty) {
      return null;
    }

    final firstRecommendation = recommendations[0] as Map<String, dynamic>;

    int? courseId;

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

