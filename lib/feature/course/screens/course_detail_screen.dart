import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/tag_color_model.dart';
import 'package:of_course/feature/report/models/report_models.dart';
import 'package:of_course/feature/report/screens/report_screen.dart';

import '../models/course_detail_models.dart';

class CourseDetailScreen extends StatefulWidget {
  final int courseId;
  final String userId;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    required this.userId,
  });

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

  NaverMapController? _mapController;
  final List<NMarker> _markers = [];
  NPolylineOverlay? _polyline;

  static const Color _backgroundColor = Color(0xFFFAFAFA);
  static const Color _mainColor = Color(0xFF003366);
  static const double _borderRadius = 8.0;
  static const double _spacingSmall = 8.0;
  static const double _spacingMedium = 16.0;
  static const double _spacingLarge = 24.0;
  static const int _maxCommentLength = 100;

  @override
  void initState() {
    super.initState();
    _loadCourseDetail();
    _commentController.addListener(_onCommentChanged);
  }

  Future<void> _loadCourseDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await SupabaseManager.shared.getCourseDetail(
        widget.courseId,
        widget.userId,
      );

      if (data == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'data null';
        });
        return;
      }

      final courseDetail = CourseDetail.fromJson(data);

      // 좋아요 개수 및 좋아요 여부 가져오기
      final likeInfo = await _loadLikeInfo();

      setState(() {
        _courseDetail = courseDetail;
        _isLiked = likeInfo['isLiked'] as bool;
        _likeCount = likeInfo['likeCount'] as int;
        _comments = List.from(courseDetail.comments);
        _isLoading = false;
      });
    } catch (e, st) {
      print(st);

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  /// 좋아요 개수 및 좋아요 여부 가져오기
  Future<Map<String, dynamic>> _loadLikeInfo() async {
    try {
      final supabase = SupabaseManager.shared.supabase;

      // 좋아요 개수 가져오기
      final likedCourses = await supabase
          .from('liked_courses')
          .select('user_id')
          .eq('course_id', widget.courseId);

      final likeCount = (likedCourses as List).length;

      // 현재 사용자 좋아요 여부 확인
      bool isLiked = false;
      if (widget.userId.isNotEmpty) {
        final userLike = await supabase
            .from('liked_courses')
            .select('user_id')
            .eq('course_id', widget.courseId)
            .eq('user_id', widget.userId)
            .maybeSingle();
        isLiked = userLike != null;
      }

      return {
        'likeCount': likeCount,
        'isLiked': isLiked,
      };
    } catch (e) {
      debugPrint('좋아요 정보 가져오기 오류: $e');
      return {
        'likeCount': 0,
        'isLiked': false,
      };
    }
  }

  void _initMarkers() {
    if (_courseDetail == null) return;

    _markers.clear();
    final List<NLatLng> points = [];

    // 세트 순서에 맞춰서 마커 생성 (숫자 표기)
    int setNumber = 1;
    for (final set in _courseDetail!.sets) {
      if (set.lat == 0.0 || set.lng == 0.0) continue;

      final pos = NLatLng(set.lat, set.lng);
      points.add(pos);

      // 마커에 숫자 표시
      _markers.add(
        NMarker(
          id: set.setId,
          position: pos,
          caption: NOverlayCaption(
            text: setNumber.toString(),
            textSize: 14,
          ),
        ),
      );
      setNumber++;
    }

    if (_mapController != null && points.isNotEmpty) {
      _mapController!.addOverlayAll(_markers.toSet());

      // ✅ polyline path 생성 (메인 컬러로 변경)
      if (points.length >= 2) {
        final polylineOverlay = NPolylineOverlay(
          id: "course_polyline_path",
          coords: points,
          color: _mainColor,
          width: 5,
        );

        _mapController!.addOverlay(polylineOverlay);
      }

      // ✅ 카메라 bounds fit
      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;

      for (final p in points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }

      final bounds = NLatLngBounds(
        southWest: NLatLng(minLat, minLng),
        northEast: NLatLng(maxLat, maxLng),
      );

      _mapController!.updateCamera(
        NCameraUpdate.fitBounds(bounds, padding: const EdgeInsets.all(60)),
      );
    }
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

  Future<void> _toggleLike() async {
    // 로그인 확인
    final userRowId = await SupabaseManager.shared.getMyUserRowId();
    if (userRowId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
      }
      return;
    }

    try {
      final supabase = SupabaseManager.shared.supabase;

      if (_isLiked) {
        // 좋아요 삭제
        await supabase
            .from('liked_courses')
            .delete()
            .eq('course_id', widget.courseId)
            .eq('user_id', userRowId);
      } else {
        // 좋아요 추가
        await supabase
            .from('liked_courses')
            .insert({
          'course_id': widget.courseId,
          'user_id': userRowId,
        });
      }

      // 좋아요 정보 다시 가져오기
      final likeInfo = await _loadLikeInfo();

      if (mounted) {
        setState(() {
          _isLiked = likeInfo['isLiked'] as bool;
          _likeCount = likeInfo['likeCount'] as int;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('좋아요 처리 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<void> _submitComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty || commentText.length > _maxCommentLength) return;

    // 로그인 확인
    final userRowId = await SupabaseManager.shared.getMyUserRowId();
    if (userRowId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
      }
      return;
    }

    try {
      // Supabase에 댓글 추가
      final supabase = SupabaseManager.shared.supabase;

      // 디버깅: 입력 데이터 확인
      debugPrint('댓글 작성 시도 - courseId: ${widget.courseId}, userRowId: $userRowId, comment: $commentText');

      final response = await supabase.from('comments').insert({
        'course_id': widget.courseId,
        'user_id': userRowId,
        'comment': commentText,
      }).select('''
        *,
        user:users!comments_user_id_fkey(nickname, profile_img)
      ''').single();

      // 디버깅: 응답 확인
      debugPrint('댓글 작성 성공 - response: $response');

      // 응답 데이터 파싱
      final user = response['user'] ?? {};
      final newComment = Comment(
        commentId: response['id'].toString(),
        commentAuthor: user['nickname'] ?? '',
        commentAvatar: user['profile_img'] ?? '',
        commentBody: response['comment'] ?? '',
        commentTime: DateTime.parse(response['created_at']),
        isCommentAuthor: true,
      );

      if (mounted) {
        setState(() {
          _comments.insert(0, newComment); // 최신 댓글을 맨 위에 추가
          _commentController.clear();
        });

        // 키보드 닫기
        FocusScope.of(context).unfocus();

        // 성공 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글이 작성되었습니다.')),
        );
      }
    } catch (e, stackTrace) {
      // 상세한 에러 로깅
      debugPrint('댓글 작성 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('댓글 작성 중 오류가 발생했습니다: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _deleteComment(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDeleteComment(commentId);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteComment(String commentId) async {
    try {
      final supabase = SupabaseManager.shared.supabase;

      // 디버깅: 삭제 시도 확인
      debugPrint('댓글 삭제 시도 - commentId: $commentId');

      // Supabase에서 댓글 삭제 (soft delete: deleted_at 업데이트)
      final response = await supabase
          .from('comments')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', int.parse(commentId))
          .select();

      // 디버깅: 삭제 응답 확인
      debugPrint('댓글 삭제 응답: $response');

      if (mounted) {
        setState(() {
          _comments.removeWhere((c) => c.commentId == commentId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글이 삭제되었습니다.')),
        );
      }
    } catch (e, stackTrace) {
      // 상세한 에러 로깅
      debugPrint('댓글 삭제 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('댓글 삭제 중 오류가 발생했습니다: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _deleteCourse() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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

  void _editCourse() {
    if (_courseDetail == null) return;
    context.push('/editcourse', extra: int.parse(_courseDetail!.courseId));
  }

  void _navigateToReport(
      String targetId,
      ReportTargetType targetType, {
        String? commentAuthor,
      }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportScreen(
          targetId: targetId,
          reportTargetType: targetType,
          reportingUser: targetType == ReportTargetType.course
              ? _courseDetail?.authorName ?? ''
              : commentAuthor ?? '',
        ),
      ),
    );
  }

  void _showImageFullScreen(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCourseDetail,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
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
          _buildCommentInputSection(),
        ],
      ),
    );
  }

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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(_spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          if (_courseDetail!.tags.isNotEmpty) ...[
            const SizedBox(height: _spacingSmall),
            Wrap(
              spacing: 6,
              children: _courseDetail!.tags.map((tag) {
                final hex = TagColorModel.getColorHex(tag);
                final bg = hex != null
                    ? Color(
                  int.parse(hex.replaceFirst('#', ''), radix: 16) +
                      0xFF000000,
                )
                    : Colors.grey.shade200;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#$tag',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _spacingMedium),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_borderRadius),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_borderRadius),
          child: Stack(
            children: [
              NaverMap(
                onMapReady: (controller) {
                  _mapController = controller;
                  _initMarkers();
                },
                options: const NaverMapViewOptions(
                  zoomGesturesEnable: true,
                  scrollGesturesEnable: true,
                  rotationGesturesEnable: true,
                  locationButtonEnable: false,
                  indoorEnable: false,
                ),
              ),

              // ✅ 줌 컨트롤 버튼 UI
              Positioned(
                right: 8,
                top: 8,
                child: Column(
                  children: [
                    _zoomButton(Icons.add, () {
                      if (_mapController != null) {
                        _mapController!.updateCamera(NCameraUpdate.zoomIn());
                      }
                    }),
                    const SizedBox(height: 8),
                    _zoomButton(Icons.remove, () {
                      if (_mapController != null) {
                        _mapController!.updateCamera(NCameraUpdate.zoomOut());
                      }
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetsSection() {
    return Column(
      children: _courseDetail!.sets.asMap().entries.map((entry) {
        final i = entry.key;
        final set = entry.value;
        return Padding(
          padding: EdgeInsets.only(
            left: _spacingMedium,
            right: _spacingMedium,
            bottom: i < _courseDetail!.sets.length - 1 ? _spacingLarge : 0,
          ),
          child: _buildSetCard(set),
        );
      }).toList(),
    );
  }

  Widget _buildSetCard(CourseSet set) {
    final hex = TagColorModel.getColorHex(set.tag);
    final Color tagColor = hex != null
        ? Color(int.parse(hex.replaceFirst('#', ''), radix: 16) + 0xFF000000)
        : Colors.grey[200]!;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (set.setImages.isNotEmpty)
              SizedBox(
                height: 150,
                child: Row(
                  children: set.setImages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final url = entry.value;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _showImageFullScreen(url),
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index < set.setImages.length - 1
                                ? _spacingSmall
                                : 0,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(_borderRadius),
                            child: Image.network(url, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: _spacingMedium),
            if (set.setAddress.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(child: Text(set.setAddress)),
                ],
              ),
            if (set.setAddress.isNotEmpty)
              const SizedBox(height: _spacingSmall),
            Text(set.setDescription),
            if (set.tag.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: _spacingSmall),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tagColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#${set.tag}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _spacingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.grey,
                ),
                onPressed: _toggleLike,
              ),
              Text('$_likeCount'),
              const SizedBox(width: _spacingLarge),
              const Icon(Icons.comment),
              const SizedBox(width: _spacingSmall),
              Text('${_comments.length}'),
            ],
          ),
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

  Widget _buildCommentsSection() {
    if (_comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(_spacingMedium),
        child: Text('댓글이 없습니다.', textAlign: TextAlign.center),
      );
    }

    return Column(
      children: _comments.map((c) => _buildCommentItem(c)).toList(),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _spacingMedium,
        vertical: _spacingSmall,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: comment.commentAvatar.isNotEmpty
                ? NetworkImage(comment.commentAvatar)
                : null,
          ),
          const SizedBox(width: _spacingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.commentAuthor,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: _spacingSmall),
                    Text(
                      comment.getRelativeTime(),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: _spacingSmall),
                Text(comment.commentBody),
              ],
            ),
          ),
          if (comment.isCommentAuthor)
            TextButton(
              onPressed: () => _deleteComment(comment.commentId),
              child: const Text(
                '삭제',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            )
          else
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
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                maxLength: _maxCommentLength,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: '댓글 작성',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_borderRadius),
                  ),
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: _spacingSmall),
            ElevatedButton(
              onPressed: !_isCommentInputEmpty ? () => _submitComment() : null,
              child: const Text('댓글'),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _zoomButton(IconData icon, VoidCallback onPressed) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4),
      ],
    ),
    child: InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 22, color: Colors.black87),
      ),
    ),
  );
}

git status