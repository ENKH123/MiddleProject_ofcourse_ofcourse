import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/tag_color_model.dart';
import 'package:of_course/feature/report/models/report_models.dart';
import 'package:of_course/feature/report/screens/report_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/course_detail_models.dart';

/// 코스(게시글) 세부정보 화면 (FO_03_03)

class CourseDetailScreen extends StatefulWidget {
  final CourseDetail? courseDetail;
  final int? courseId;

  const CourseDetailScreen({
    super.key,
    this.courseDetail,
    this.courseId,
  }) : assert(courseDetail != null || courseId != null,
  'courseDetail 또는 courseId 중 하나는 필수입니다.');

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  CourseDetail? _courseDetail;
  bool _isLoading = false;
  String? _errorMessage;

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

    if (widget.courseId != null) {
      _loadCourseFromSupabase();
    } else if (widget.courseDetail != null) {
      _courseDetail = widget.courseDetail;
      _initializeFromCourseDetail();
    }

    _commentController.addListener(_onCommentChanged);
  }

  Future<void> _loadCourseFromSupabase() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;
      final courseId = widget.courseId!;

      // 코스 기본 정보 가져오기 (외래 키 힌트 없이)
      final course = await supabase
          .from('courses')
          .select('*')
          .eq('id', courseId)
          .maybeSingle();

      if (course == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = '코스를 찾을 수 없습니다.';
        });
        return;
      }

      // 작성자 정보 별도 쿼리로 가져오기
      final authorId = course['author_id'] as String?;
      String authorName = '';
      String authorProfile = '';

      if (authorId != null) {
        final author = await supabase
            .from('users')
            .select('nickname, profile_img')
            .eq('id', authorId)
            .maybeSingle();

        if (author != null) {
          authorName = author['nickname'] as String? ?? '';
          authorProfile = author['profile_img'] as String? ?? '';
        }
      }

      // 코스 세트들 가져오기 (courses 테이블의 set_01~set_05를 통해)
      final List<int> setIds = [];
      if (course['set_01'] != null) setIds.add(course['set_01'] as int);
      if (course['set_02'] != null) setIds.add(course['set_02'] as int);
      if (course['set_03'] != null) setIds.add(course['set_03'] as int);
      if (course['set_04'] != null) setIds.add(course['set_04'] as int);
      if (course['set_05'] != null) setIds.add(course['set_05'] as int);

      // 세트 데이터 변환
      final List<Map<String, dynamic>> processedSets = [];
      final Set<String> allTags = {};

      // 각 세트 ID에 대해 개별 조회 (성능 최적화: 고유 ID만 조회)
      final Map<int, Map<String, dynamic>> setMap = {};
      for (final setId in setIds) {
        if (setMap.containsKey(setId)) continue; // 이미 조회한 세트는 스킵

        final set = await supabase
            .from('course_sets')
            .select('''
              *,
              tag_info:tags!course_sets_tag_fkey(id, type)
            ''')
            .eq('id', setId)
            .maybeSingle();

        if (set != null) {
          setMap[setId] = set;
        }
      }

      // 세트 ID 순서대로 처리
      for (final setId in setIds) {
        final set = setMap[setId];
        if (set == null) continue;

        final List<String> images = [];
        if (set['img_01'] != null && (set['img_01'] as String).isNotEmpty) {
          images.add(set['img_01'] as String);
        }
        if (set['img_02'] != null && (set['img_02'] as String).isNotEmpty) {
          images.add(set['img_02'] as String);
        }
        if (set['img_03'] != null && (set['img_03'] as String).isNotEmpty) {
          images.add(set['img_03'] as String);
        }

        if (set['tag_info'] != null) {
          final tagName = set['tag_info']['type'] as String?;
          if (tagName != null) {
            allTags.add(tagName);
          }
        }

        processedSets.add({
          'id': set['id'],
          'images': images,
          'address': set['address'] ?? '',
          'description': set['description'] ?? '',
          'tag': set['tag_info'] != null ? (set['tag_info']['type'] as String) : '',
        });
      }

      // 댓글 가져오기 (외래 키 힌트 없이)
      final allComments = await supabase
          .from('comments')
          .select('*')
          .eq('course_id', courseId)
          .order('created_at', ascending: false)
          .limit(50);

      final comments = (allComments as List)
          .where((comment) => comment['deleted_at'] == null)
          .toList();

      // 댓글 작성자 정보 별도 쿼리로 가져오기 (성능 최적화: 고유 사용자 ID 수집 후 개별 조회)
      final Set<String> userIds = {};
      for (var comment in comments) {
        final userId = comment['user_id'] as String?;
        if (userId != null) {
          userIds.add(userId);
        }
      }

      // 모든 댓글 작성자 정보 가져오기 (고유 ID에 대해서만 조회)
      final Map<String, Map<String, dynamic>> userMap = {};
      for (final userId in userIds) {
        final user = await supabase
            .from('users')
            .select('id, nickname, profile_img')
            .eq('id', userId)
            .maybeSingle();

        if (user != null) {
          userMap[userId] = {
            'nickname': user['nickname'] as String? ?? '',
            'profile_img': user['profile_img'] as String? ?? '',
          };
        }
      }

      final List<Map<String, dynamic>> processedComments = [];
      for (var comment in comments) {
        final userId = comment['user_id'] as String?;
        final userInfo = userId != null ? userMap[userId] : null;

        processedComments.add({
          'id': comment['id'],
          'user_id': userId,
          'author': userInfo?['nickname'] ?? '',
          'avatar': userInfo?['profile_img'] ?? '',
          'body': comment['comment'] ?? '',
          'time': comment['created_at'],
          'is_author': userId == currentUserId,
        });
      }

      // 최종 데이터 구성
      final data = {
        'id': course['id'],
        'title': course['title'] ?? '',
        'marker_image': course['marker_image'] ?? '',
        'author_name': authorName,
        'author_profile': authorProfile,
        'tags': allTags.toList(),
        'sets': processedSets,
        'created_at': course['created_at'],
        'is_author': course['author_id'] == currentUserId,
        'like_count': 0,
        'is_liked': false,
        'comment_count': processedComments.length,
        'comments': processedComments,
      };

      final courseDetail = CourseDetail.fromJson(data);
      setState(() {
        _courseDetail = courseDetail;
        _isLoading = false;
      });
      _initializeFromCourseDetail();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '데이터를 불러오는 중 오류가 발생했습니다: $e';
      });
    }
  }

  void _initializeFromCourseDetail() {
    if (_courseDetail == null) return;

    _isLiked = _courseDetail!.isLiked;
    _likeCount = _courseDetail!.likeCount;

    _comments = List.from(_courseDetail!.comments);
  }

  @override
  void dispose() {
    _commentController.removeListener(_onCommentChanged);
    _commentController.dispose();
    super.dispose();
  }

  void _onCommentChanged() {
    setState(() {
      _isCommentInputEmpty = _commentController.text.trim().isEmpty;
    });
  }

  /// 좋아요 토글
  /// TODO: Supabase API 호출로 변경 필요
  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    // TODO: Supabase의 liked_courses 테이블에 좋아요 추가/삭제
  }

  /// 댓글 작성
  void _submitComment() {
    final commentText = _commentController.text.trim();

    if (commentText.isEmpty || commentText.length > _maxCommentLength) {
      return;
    }


    final newComment = Comment(
      commentId: DateTime.now().millisecondsSinceEpoch.toString(),
      commentAuthor: '',
      commentAvatar: '',
      commentBody: commentText,
      commentTime: DateTime.now(),
      isCommentAuthor: true,
    );

    setState(() {
      _comments.add(newComment);
      _commentController.clear();
    });
  }

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

              setState(() {
                _comments.removeWhere((c) => c.commentId == commentId);
              });
              Navigator.pop(context);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 게시글 삭제
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
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 게시글 수정
  void _editCourse() {
    if (_courseDetail == null) return;

    // 코스 ID를 쿼리 파라미터로 전달하여 수정 화면으로 이동
    context.push('/write?id=${_courseDetail!.courseId}');
  }

  /// 신고 화면으로 이동
  void _navigateToReport(String targetId, ReportTargetType targetType, {String? commentAuthor}) {
    String reportingUserNickname = '';

    if (targetType == ReportTargetType.course) {
      // 코스 신고: 코스 작성자 닉네임
      reportingUserNickname = _courseDetail?.authorName ?? '';
    } else if (targetType == ReportTargetType.comment) {
      // 댓글 신고: 댓글 작성자 닉네임
      reportingUserNickname = commentAuthor ?? '';
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportScreen(
          targetId: targetId,
          reportTargetType: targetType,
          reportingUser: reportingUserNickname,
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
    // 로딩 중
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 에러 발생
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadCourseFromSupabase(),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    // 데이터 없음
    if (_courseDetail == null) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: _buildAppBar(),
        body: const Center(child: Text('코스 정보를 불러올 수 없습니다.')),
      );
    }

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
                  _courseDetail!.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // 작성자만 수정/삭제 버튼 표시
              if (_courseDetail!.isAuthor) ...[
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
                '작성자: ${_courseDetail!.authorName}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(width: _spacingMedium),
              Text(
                '작성일: ${_formatDate(_courseDetail!.createdAt)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          // 태그 목록
          if (_courseDetail!.tags.isNotEmpty) ...[
            const SizedBox(height: _spacingSmall),
            Wrap(
              spacing: _spacingSmall,
              runSpacing: _spacingSmall,
              children: _courseDetail!.tags.map((tag) {
                final colorHex = TagColorModel.getColorHex(tag);
                final backgroundColor = colorHex != null
                    ? Color(int.parse(colorHex.replaceFirst('#', ''), radix: 16) + 0xFF000000)
                    : Colors.grey[200];
                return Chip(
                  label: Text(tag),
                  backgroundColor: backgroundColor,
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
          _courseDetail!.markerImage.isNotEmpty &&
              _courseDetail!.markerImage.startsWith('http')
              ? Image.network(
            _courseDetail!.markerImage,
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
      children: _courseDetail!.sets.asMap().entries.map((entry) {
        final index = entry.key;
        final set = entry.value;
        return Padding(
          padding: EdgeInsets.only(
            left: _spacingMedium,
            right: _spacingMedium,
            // 마지막 세트가 아닌 경우에만 하단 여백 추가
            bottom: index < _courseDetail!.sets.length - 1
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
      color: Colors.white,
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
            if (set.tag.isNotEmpty) ...[
              Builder(
                builder: (context) {
                  final colorHex = TagColorModel.getColorHex(set.tag);
                  final backgroundColor = colorHex != null
                      ? Color(int.parse(colorHex.replaceFirst('#', ''), radix: 16) + 0xFF000000)
                      : Colors.blue[50];
                  return Chip(
                    label: Text(set.tag),
                    backgroundColor: backgroundColor,
                    padding: EdgeInsets.zero,
                  );
                },
              ),
            ],
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
              _courseDetail!.courseId,
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
                commentAuthor: comment.commentAuthor,
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

