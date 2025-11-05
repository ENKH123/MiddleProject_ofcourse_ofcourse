/// 코스 세부정보 화면의 데이터 모델

// ============================================================================
// 코스 세부정보 모델
// ============================================================================

/// 코스 세부정보 모델 1번 항목
class CourseDetail {
  /// 코스 ID (UUID 형식, 36자)
  final String courseId;

  /// 게시글 제목 (최대 20자) 2번 항목
  final String title;

  /// 대표 마커 이미지 URL 3번 항목
  final String markerImage;

  /// 세트 목록 4번 항목
  final List<CourseSet> sets;

  /// 상단 태그 집계 9번 항목

  final List<String> tags;

  /// 작성자 이름 10번 항목

  final String authorName;

  /// 작성자 프로필 이미지 11번 항목

  final String authorProfile;

  /// 총 좋아요 개수 12번 항목
  final int likeCount;

  /// 사용자 개별 좋아요 상태 13번 항목

  final bool isLiked;

  /// 총 댓글 수 14번 항목

  final int commentCount;

  /// 댓글 목록 (최대 50개) 15번 항목

  final List<Comment> comments;

  /// 작성일 (ISO8601 형식)
  final DateTime createdAt;

  /// 현재 사용자가 작성자인지 여부
  final bool isAuthor;

  CourseDetail({
    required this.courseId,
    required this.title,
    required this.markerImage,
    required this.sets,
    required this.tags,
    required this.authorName,
    required this.authorProfile,
    required this.likeCount,
    required this.isLiked,
    required this.commentCount,
    required this.comments,
    required this.createdAt,
    required this.isAuthor,
  });
}

// ============================================================================
// 코스 세트 모델
// ============================================================================

/// 코스 상세 정보를 구성하는 개별 세트입니다. 4-7번 항목
class CourseSet {
  /// 세트 ID (UUID 형식, 36자) 5번 항목
  final String setId;

  /// 세트 내 이미지 URL 리스트 (1~3개) 6번 항목
  final List<String> setImages;

  /// 세트별 주소
  /// 장소의 주소 정보입니다.
  final String setAddress;

  /// 세트별 텍스트 내용 (최대 200자) 7번 항목
  final String setDescription;

  /// 세트별 단일 태그 (최대 20자) 8번 항목
  final String tag;

  CourseSet({
    required this.setId,
    required this.setImages,
    required this.setAddress,
    required this.setDescription,
    required this.tag,
  });
}

// ============================================================================
// 댓글 모델
// ============================================================================

/// 댓글 모델
class Comment {
  /// 댓글 ID (UUID 형식, 36자)
  final String commentId;

  /// 댓글 작성자 이름 (닉네임, 최대 20자) 17번 항목
  final String commentAuthor;

  /// 댓글 작성자 프로필 이미지 URL 18번 항목
  final String commentAvatar;

  /// 댓글 본문 (최대 100자) 19번 항목
  final String commentBody;

  /// 댓글 작성 시각 (ISO8601 형식) 20번 항목
  final DateTime commentTime;

  /// 현재 사용자가 댓글 작성자인지 여부 true인 경우 삭제 버튼이, false인 경우 신고 버튼이 표시됩니다.
  final bool isCommentAuthor;

  Comment({
    required this.commentId,
    required this.commentAuthor,
    required this.commentAvatar,
    required this.commentBody,
    required this.commentTime,
    required this.isCommentAuthor,
  });

  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(commentTime);

    if (difference.inMinutes < 1) {
      return '방금 전';
    }
    else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    }
    else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    }
    else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    }
    else {
      return '${commentTime.year}/${commentTime.month.toString().padLeft(2, '0')}/${commentTime.day.toString().padLeft(2, '0')}';
    }
  }
}
