import 'package:flutter/material.dart';
import 'package:of_course/feature/report/models/report_models.dart';
import 'package:of_course/feature/report/screens/report_screen.dart';

import '../models/course_detail_models.dart';

/// 코스(게시글) 세부정보 화면 (FO_03_03)

class CourseDetailScreen extends StatefulWidget {
  final CourseDetail courseDetail;

  const CourseDetailScreen({super.key, required this.courseDetail});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late bool _isLiked;
  late int _likeCount;

  late List<Comment> _comments;
  final TextEditingController _commentController = TextEditingController();
  bool _isCommentInputEmpty = true;

  static const Color _backgroundColor = Color(0xFFFAFAFA);
  static const double _borderRadius = 8.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 16.0;
  static const double _spacingLarge = 24.0;
  static const int _maxCommentLength = 100;

  /// 위젯 초기화
  @override
  void initState() {
    super.initState();
    // 초기 좋아요 상태 설정
    _isLiked = widget.courseDetail.isLiked;
    _likeCount = widget.courseDetail.likeCount;

    // 댓글 목록 복사 (원본 데이터를 변경하지 않기 위해)
    _comments = List.from(widget.courseDetail.comments);

    // 댓글 입력 필드 변경 감지 리스너 등록
    _commentController.addListener(_onCommentChanged);
  }

  @override
  void dispose() {
    _commentController.removeListener(_onCommentChanged);
    _commentController.dispose();
    super.dispose();
  }

  /// 댓글 입력 필드 변경 감지
  void _onCommentChanged() {
    setState(() {
      _isCommentInputEmpty = _commentController.text.trim().isEmpty;
    });
  }

  /// 좋아요 토글
  /// TODO: 실제 API 호출로 변경 필요
  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      // 좋아요를 누르면 +1, 취소하면 -1
      _likeCount += _isLiked ? 1 : -1;
    });
    // TODO: 실제 API 호출로 변경 필요
  }

  /// 댓글 작성
  /// TODO: 실제 API 호출로 변경 필요
  void _submitComment() {
    final commentText = _commentController.text.trim();

    // 유효성 검사
    if (commentText.isEmpty || commentText.length > _maxCommentLength) {
      return;
    }

    // 새 댓글 생성
    // TODO: 실제 사용자 정보를 가져와서 설정해야 함
    final newComment = Comment(
      commentId: DateTime.now().millisecondsSinceEpoch.toString(),
      commentAuthor: '', // TODO: 실제 사용자 정보로 변경
      commentAvatar: '', // TODO: 실제 사용자 프로필 이미지로 변경
      commentBody: commentText,
      commentTime: DateTime.now(),
      isCommentAuthor: true, // 자신이 작성한 댓글이므로 삭제 가능
    );

    // 댓글 목록에 추가
    setState(() {
      _comments.add(newComment);
      _commentController.clear(); // 입력 필드 초기화
    });
    // TODO: 실제 API 호출로 변경 필요
  }

  /// 댓글 삭제
  /// TODO: 실제 API 호출로 변경 필요
  void _deleteComment(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('댓글을 삭제하시겠습니까?'),
        actions: [
          // 취소 버튼
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          // 삭제 버튼
          TextButton(
            onPressed: () {
              // 댓글 목록에서 해당 댓글 제거
              setState(() {
                _comments.removeWhere((c) => c.commentId == commentId);
              });
              Navigator.pop(context); // 다이얼로그 닫기
              // TODO: 실제 API 호출로 변경 필요
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 게시글 삭제
  /// TODO: 실제 API 호출로 변경 필요
  void _deleteCourse() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('게시글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              // TODO: 실제 API 호출로 변경 필요
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 게시글 수정
  /// TODO: 실제 수정 화면으로 이동하도록 구현 필요
  void _editCourse() {
    // TODO: 게시글 수정 화면으로 이동
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('게시글 수정 기능은 준비 중입니다.')));
  }

  /// 신고 화면으로 이동
  void _navigateToReport(String targetId, ReportTargetType targetType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportScreen(
          targetId: targetId,
          reportTargetType: targetType,
          reportingUser: targetType == ReportTargetType.course
              ? widget.courseDetail.authorName
              : '',
        ),
      ),
    );
  }

  /// 이미지 확대 보기
  void _showImageFullScreen(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              // 확대/축소 및 팬 기능 제공
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // 이미지 로드 실패 시 아이콘 표시
                  return const Center(
                    child: Icon(Icons.image, color: Colors.white, size: 100),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // 유틸리티 메서드
  // ============================================================================

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  // ============================================================================
  // UI 빌드 메서드
  // ============================================================================

  /// 화면 빌드
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 스크롤 가능한 콘텐츠 영역
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: _spacingMedium),
                  _buildMapSection(),
                  const SizedBox(height: _spacingLarge),
                  _buildSetsSection(),
                  const SizedBox(height: _spacingLarge),
                  _buildEngagementSection(),
                  const SizedBox(height: _spacingMedium),
                  _buildCommentsSection(),
                  const SizedBox(height: _spacingLarge),
                ],
              ),
            ),
          ),
          // 하단 고정 댓글 입력 섹션
          _buildCommentInputSection(),
        ],
      ),
    );
  }

  /// AppBar 빌드
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        '코스 세부정보',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// 헤더 섹션 빌드
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(_spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목과 수정/삭제 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.courseDetail.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // 작성자만 수정/삭제 버튼 표시
              if (widget.courseDetail.isAuthor) ...[
                TextButton(onPressed: _editCourse, child: const Text('수정')),
                TextButton(
                  onPressed: _deleteCourse,
                  child: const Text('삭제', style: TextStyle(color: Colors.red)),
                ),
              ],
            ],
          ),
          const SizedBox(height: _spacingSmall),
          // 작성자 정보
          Row(
            children: [
              Text(
                '작성자: ${widget.courseDetail.authorName}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(width: _spacingMedium),
              Text(
                '작성일: ${_formatDate(widget.courseDetail.createdAt)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          // 태그 목록
          if (widget.courseDetail.tags.isNotEmpty) ...[
            const SizedBox(height: _spacingSmall),
            Wrap(
              spacing: _spacingSmall,
              runSpacing: _spacingSmall,
              children: widget.courseDetail.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: Colors.grey[200],
                  padding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// 지도 섹션 빌드
  Widget _buildMapSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _spacingMedium),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(_borderRadius),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_borderRadius),
          child:
              widget.courseDetail.markerImage.isNotEmpty &&
                  widget.courseDetail.markerImage.startsWith('http')
              ? Image.network(
                  widget.courseDetail.markerImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // 이미지 로드 실패 시 지도 아이콘 표시
                    return const Center(child: Icon(Icons.map, size: 50));
                  },
                )
              : const Center(child: Icon(Icons.map, size: 50)),
        ),
      ),
    );
  }

  /// 세트 섹션 빌드
  Widget _buildSetsSection() {
    return Column(
      children: widget.courseDetail.sets.asMap().entries.map((entry) {
        final index = entry.key;
        final set = entry.value;
        return Padding(
          padding: EdgeInsets.only(
            left: _spacingMedium,
            right: _spacingMedium,
            // 마지막 세트가 아닌 경우에만 하단 여백 추가
            bottom: index < widget.courseDetail.sets.length - 1
                ? _spacingLarge
                : 0,
          ),
          child: _buildSetCard(set),
        );
      }).toList(),
    );
  }

  /// 세트 카드 빌드
  Widget _buildSetCard(CourseSet set) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지들 (한 줄에 모두 표시)
            if (set.setImages.isNotEmpty)
              SizedBox(
                height: 150,
                child: Row(
                  children: set.setImages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final imageUrl = entry.value;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          // 마지막 이미지가 아닌 경우에만 오른쪽 여백 추가
                          right: index < set.setImages.length - 1
                              ? _spacingSmall
                              : 0,
                        ),
                        child: GestureDetector(
                          // 이미지 클릭 시 확대 보기
                          onTap: () => _showImageFullScreen(imageUrl),
                          child: Container(
                            width: double.infinity,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(
                                _borderRadius,
                              ),
                              border: Border.all(color: Colors.grey[400]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                _borderRadius,
                              ),
                              child:
                                  imageUrl.isNotEmpty &&
                                      imageUrl.startsWith('http')
                                  ? Image.network(
                                      imageUrl,
                                      width: double.infinity,
                                      height: 150,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value:
                                                    loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            // 이미지 로드 실패 시 아이콘 표시
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: Icon(
                                                  Icons.image,
                                                  size: 50,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            );
                                          },
                                    )
                                  : Container(
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(
                                          Icons.image,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: _spacingMedium),
            // 주소
            if (set.setAddress.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      set.setAddress,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            if (set.setAddress.isNotEmpty)
              const SizedBox(height: _spacingSmall),
            // 텍스트 설명
            Text(set.setDescription, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: _spacingSmall),
            // 태그
            if (set.tag.isNotEmpty)
              Chip(
                label: Text(set.tag),
                backgroundColor: Colors.blue[50],
                padding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
    );
  }

  /// 참여 섹션 빌드
  Widget _buildEngagementSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _spacingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 왼쪽: 좋아요 및 댓글 수
          Row(
            children: [
              // 좋아요 버튼
              IconButton(
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.grey,
                ),
                onPressed: _toggleLike,
              ),
              // 좋아요 개수
              Text('$_likeCount', style: const TextStyle(fontSize: 16)),
              const SizedBox(width: _spacingLarge),
              // 댓글 아이콘
              const Icon(Icons.comment, size: 20),
              const SizedBox(width: _spacingSmall),
              // 댓글 개수
              Text('${_comments.length}', style: const TextStyle(fontSize: 16)),
            ],
          ),
          // 오른쪽: 신고 버튼
          TextButton(
            onPressed: () => _navigateToReport(
              widget.courseDetail.courseId,
              ReportTargetType.course,
            ),
            child: const Text('신고'),
          ),
        ],
      ),
    );
  }

  /// 댓글 섹션 빌드
  Widget _buildCommentsSection() {
    if (_comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(_spacingMedium),
        child: Text(
          '댓글이 없습니다.',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: _comments.map((comment) {
        return _buildCommentItem(comment);
      }).toList(),
    );
  }

  /// 댓글 아이템 빌드
  Widget _buildCommentItem(Comment comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _spacingMedium,
        vertical: _spacingSmall,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 이미지
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[300],
            backgroundImage:
                comment.commentAvatar.isNotEmpty &&
                    comment.commentAvatar.startsWith('http')
                ? NetworkImage(comment.commentAvatar)
                : null,
            child:
                comment.commentAvatar.isEmpty ||
                    !comment.commentAvatar.startsWith('http')
                ? const Icon(Icons.person, size: 16)
                : null,
          ),
          const SizedBox(width: _spacingSmall),
          // 댓글 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 작성자 이름과 작성 시간
                Row(
                  children: [
                    Text(
                      comment.commentAuthor,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: _spacingSmall),
                    Text(
                      comment.getRelativeTime(),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: _spacingSmall),
                // 댓글 본문
                Text(comment.commentBody, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          // 삭제/신고 버튼
          if (comment.isCommentAuthor)
            // 자신이 작성한 댓글: 삭제 버튼
            TextButton(
              onPressed: () => _deleteComment(comment.commentId),
              child: const Text(
                '삭제',
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
            )
          else
            // 다른 사람이 작성한 댓글: 신고 버튼
            TextButton(
              onPressed: () => _navigateToReport(
                comment.commentId,
                ReportTargetType.comment,
              ),
              child: const Text('신고', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  /// 댓글 입력 섹션 빌드
  Widget _buildCommentInputSection() {
    return Container(
      padding: const EdgeInsets.all(_spacingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300]!,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 댓글 입력 필드
            Expanded(
              child: TextField(
                controller: _commentController,
                maxLength: _maxCommentLength,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: '댓글 작성',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_borderRadius),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: _spacingSmall),
            // 댓글 등록 버튼
            ElevatedButton(
              onPressed: !_isCommentInputEmpty ? _submitComment : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_borderRadius),
                ),
              ),
              child: const Text('댓글'),
            ),
          ],
        ),
      ),
    );
  }
}

/// todo 예시 코스 세부정보 데이터 생성 추후 삭제
CourseDetail createExampleCourseDetail() {
  return CourseDetail(
    courseId: 'course-example-001',
    title: '코스 제목',
    markerImage: 'https://via.placeholder.com/400x200',
    sets: [
      CourseSet(
        setId: 'set-example-001',
        setImages: [
          'https://via.placeholder.com/300x200',
          'https://via.placeholder.com/300x200',
          'https://via.placeholder.com/300x200',
        ],
        setAddress: '서울특별시 종로구 세종대로',
        setDescription: '첫 번째 장소입니다.',
        tag: '#명소',
      ),
      CourseSet(
        setId: 'set-example-002',
        setImages: [
          'https://via.placeholder.com/300x200',
          'https://via.placeholder.com/300x200',
        ],
        setAddress: '서울특별시 강남구 테헤란로',
        setDescription: '두 번째 장소입니다.',
        tag: '#맛집',
      ),
      CourseSet(
        setId: 'set-example-003',
        setImages: ['https://via.placeholder.com/300x200'],
        setAddress: '서울특별시 중구 명동길',
        setDescription: '세 번째 장소입니다.',
        tag: '#쇼핑',
      ),
    ],
    tags: ['#명소', '#맛집', '#쇼핑'],
    authorName: '작성자',
    authorProfile: 'https://via.placeholder.com/100',
    likeCount: 3,
    isLiked: false,
    commentCount: 5,
    comments: [
      Comment(
        commentId: 'comment-example-001',
        commentAuthor: '댓글 1',
        commentAvatar: 'https://via.placeholder.com/50',
        commentBody: '댓글 1',
        commentTime: DateTime.now().subtract(const Duration(minutes: 5)),
        isCommentAuthor: false,
      ),
      Comment(
        commentId: 'comment-example-002',
        commentAuthor: '댓글 2',
        commentAvatar: 'https://via.placeholder.com/50',
        commentBody: '댓글 2.',
        commentTime: DateTime.now().subtract(const Duration(hours: 2)),
        isCommentAuthor: false,
      ),
      Comment(
        commentId: 'comment-example-003',
        commentAuthor: '댓글 3',
        commentAvatar: 'https://via.placeholder.com/50',
        commentBody: '댓글 3 ',
        commentTime: DateTime.now().subtract(const Duration(days: 1)),
        isCommentAuthor: false,
      ),
      Comment(
        commentId: 'comment-example-004',
        commentAuthor: '작성자 댓글',
        commentAvatar: 'https://via.placeholder.com/50',
        commentBody: '댓글.',
        commentTime: DateTime.now().subtract(const Duration(days: 2)),
        isCommentAuthor: true,
      ),
      Comment(
        commentId: 'comment-example-005',
        commentAuthor: '댓글 4',
        commentAvatar: 'https://via.placeholder.com/50',
        commentBody: '댓글 4',
        commentTime: DateTime.now().subtract(const Duration(days: 3)),
        isCommentAuthor: false,
      ),
    ],
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    isAuthor: false,
  );
}
