import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/tag_color_model.dart';
import 'package:of_course/feature/report/models/report_models.dart';
import 'package:of_course/feature/report/screens/report_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/course_detail_models.dart';

class CourseDetailScreen extends StatefulWidget {
  final int courseId;
  final String userId;
  final String? recommendationReason; // 추천 페이지에서 전달받은 추천 사유

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    required this.userId,
    this.recommendationReason,
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
  String? _recommendationReason; // 코스 추천 사유
  final TextEditingController _commentController = TextEditingController();
  bool _isCommentInputEmpty = true;

  NaverMapController? _mapController;
  final List<NMarker> _markers = [];
  final Map<String, NLatLng> _markerPositions = {}; // 마커 ID와 위치 매핑
  NPolylineOverlay? _polyline;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _setCardKeys = {};
  final GlobalKey _mapSectionKey = GlobalKey();

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
    _recommendationReason = widget.recommendationReason;
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

      // 세트 카드 키 초기화
      _setCardKeys.clear();
      for (final set in courseDetail.sets) {
        _setCardKeys[set.setId] = GlobalKey();
      }
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

      return {'likeCount': likeCount, 'isLiked': isLiked};
    } catch (e) {
      debugPrint('좋아요 정보 가져오기 오류: $e');
      return {'likeCount': 0, 'isLiked': false};
    }
  }

  void _initMarkers() {
    if (_courseDetail == null) return;

    _markers.clear();
    _markerPositions.clear();
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
          caption: NOverlayCaption(text: setNumber.toString(), textSize: 14),
        ),
      );
      // 마커 위치 저장
      _markerPositions[set.setId] = pos;
      setNumber++;
    }

    if (_mapController != null && points.isNotEmpty) {
      _mapController!.addOverlayAll(_markers.toSet());

      if (points.length >= 2) {
        final polylineOverlay = NPolylineOverlay(
          id: "course_polyline_path",
          coords: points,
          color: _mainColor,
          width: 5,
        );

        _mapController!.addOverlay(polylineOverlay);
      }

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
    _scrollController.dispose();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
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

        // learningData 업데이트: label을 0으로 설정
        await _updateLearningData(supabase, userRowId, widget.courseId, 0);
      } else {
        // 좋아요 추가
        await supabase.from('liked_courses').insert({
          'course_id': widget.courseId,
          'user_id': userRowId,
        });

        // learningData 업데이트: label을 1로 설정
        await _updateLearningData(supabase, userRowId, widget.courseId, 1);
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('좋아요 처리 중 오류가 발생했습니다: $e')));
      }
    }
  }

  /// learningData 테이블 업데이트 (upsert)
  Future<void> _updateLearningData(
      SupabaseClient supabase,
      String userId,
      int courseId,
      int label,
      ) async {
    try {
      // 먼저 코스 제목 가져오기
      final courseData = await supabase
          .from('courses')
          .select('title')
          .eq('id', courseId)
          .maybeSingle();

      final courseTitle = courseData?['title'] as String? ?? '';

      // learningData에서 기존 레코드 확인
      final existingData = await supabase
          .from('learningData')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .maybeSingle();

      if (existingData != null) {
        // 기존 레코드가 있으면 업데이트
        await supabase
            .from('learningData')
            .update({
          'label': label,
        })
            .eq('id', existingData['id']);
      } else {
        // 기존 레코드가 없으면 새로 생성
        await supabase.from('learningData').insert({
          'user_id': userId,
          'course_id': courseId,
          'label': label,
          'title': courseTitle,
        });
      }
    } catch (e) {
      debugPrint('learningData 업데이트 오류: $e');
      // learningData 업데이트 실패해도 좋아요 기능은 계속 진행
    }
  }

  Future<void> _submitComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty || commentText.length > _maxCommentLength) return;

    // 로그인 확인
    final userRowId = await SupabaseManager.shared.getMyUserRowId();
    if (userRowId == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      }
      return;
    }

    try {
      // Supabase에 댓글 추가
      final supabase = SupabaseManager.shared.supabase;

      // 디버깅: 입력 데이터 확인
      debugPrint(
        '댓글 작성 시도 - courseId: ${widget.courseId}, userRowId: $userRowId, comment: $commentText',
      );

      final response = await supabase
          .from('comments')
          .insert({
        'course_id': widget.courseId,
        'user_id': userRowId,
        'comment': commentText,
      })
          .select('''
        *,
        user:users!comments_user_id_fkey(nickname, profile_img)
      ''')
          .single();

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
          _comments.add(newComment); // 최신 댓글을 맨 아래에 추가
          _commentController.clear();
        });

        // 키보드 닫기
        FocusScope.of(context).unfocus();

        // 성공 메시지
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('댓글이 작성되었습니다.')));
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

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('댓글이 삭제되었습니다.')));
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

  Future<void> _deleteCourseConfirmed() async {
    try {
      final supabase = SupabaseManager.shared.supabase;
      final courseId = widget.courseId;

      // 1️⃣ 코스 세트 ID 가져오기
      final courseData = await supabase
          .from('courses')
          .select('set_01, set_02, set_03, set_04, set_05')
          .eq('id', courseId)
          .maybeSingle();

      if (courseData == null) {
        debugPrint('❌ 코스 데이터를 찾을 수 없음');
        return;
      }

      final setIds = [
        courseData['set_01'],
        courseData['set_02'],
        courseData['set_03'],
        courseData['set_04'],
        courseData['set_05'],
      ].where((id) => id != null).toList();

      debugPrint('📍 관련 세트 ID들: $setIds');

      // 2️⃣ 관련 세트 이미지 URL들 가져오기
      List<Map<String, dynamic>> setRows = [];
      if (setIds.isNotEmpty) {
        setRows = await supabase
            .from('course_sets')
            .select('img_01, img_02, img_03')
            .inFilter('id', setIds);
      }

      // 3️⃣ 각 세트의 이미지 버킷에서 삭제
      for (final set in setRows) {
        final imageUrls = [set['img_01'], set['img_02'], set['img_03']]
            .where(
              (url) =>
          url != null && url != "null" && url.toString().isNotEmpty,
        )
            .toList();

        for (final url in imageUrls) {
          try {
            final baseUrl =
                'https://dbhecolzljfrmgtdjwie.supabase.co/storage/v1/object/public/course_set_image/course_set/';
            final filePath = url.toString().substring(baseUrl.length);
            await supabase.storage.from('course_set_image').remove([
              'course_set/$filePath',
            ]);
          } catch (e) {
            debugPrint("⚠️ 이미지 삭제 실패: $e");
          }
        }
      }

      await supabase.from('comments').delete().eq('course_id', courseId);

      await supabase.from('liked_courses').delete().eq('course_id', courseId);

      for (final setId in setIds) {
        await supabase.from('course_sets').delete().eq('id', setId);
      }

      await supabase.from('courses').delete().eq('id', courseId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('코스 및 관련 세트, 이미지, 댓글, 좋아요가 모두 삭제되었습니다.'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e, st) {
      debugPrint('❌ 코스 삭제 오류: $e');
      debugPrint('스택트레이스: $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('코스 삭제 중 오류가 발생했습니다: $e'),
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
        content: const Text('정말 이 코스를 삭제하시겠습니까?\n연관된 댓글과 좋아요도 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCourseConfirmed();
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

  /// 지도 탭 이벤트 처리 - 가장 가까운 마커 찾기
  void _handleMapTap(NLatLng tappedLocation) {
    if (_courseDetail == null || _markerPositions.isEmpty) return;

    String? closestMarkerId;
    double minDistance = double.infinity;
    const double maxTapDistanceMeters = 100.0; // 약 100m 이내

    // 탭된 위치에서 가장 가까운 마커 찾기
    for (final entry in _markerPositions.entries) {
      final markerId = entry.key;
      final markerPos = entry.value;
      final distance = _calculateDistance(
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

    // 가장 가까운 마커가 있으면 해당 세트로 스크롤
    if (closestMarkerId != null) {
      _scrollToSetCard(closestMarkerId);
    }
  }

  /// 두 좌표 간 거리 계산 (하버사인 공식, 미터 단위)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
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

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);

  /// 마커 클릭 시 해당 세트 카드로 스크롤
  void _scrollToSetCard(String setId) {
    final key = _setCardKeys[setId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1, // 화면 상단에서 약간 아래 위치
      );
    }
  }

  /// 세트 주소 클릭 시 지도 섹션으로 스크롤하고 해당 마커로 이동
  void _moveToMarker(String setId) {
    // 먼저 지도 섹션으로 스크롤
    if (_mapSectionKey.currentContext != null) {
      Scrollable.ensureVisible(
        _mapSectionKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }

    // 지도가 준비되면 해당 마커로 이동
    if (_courseDetail == null) return;

    final set = _courseDetail!.sets.firstWhere(
          (s) => s.setId == setId,
      orElse: () => _courseDetail!.sets.first,
    );

    if (set.lat == 0.0 || set.lng == 0.0) return;

    // 지도 컨트롤러가 준비될 때까지 약간의 지연 후 이동
    Future.delayed(const Duration(milliseconds: 600), () {
      if (_mapController != null) {
        _mapController!.updateCamera(
          NCameraUpdate.withParams(
            target: NLatLng(set.lat, set.lng),
            zoom: 15.0,
          ),
        );
      }
    });
  }

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

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    _buildHeader(),

                    if (_recommendationReason != null) ...[
                      _buildRecommendationReason(),
                      const SizedBox(height: 24), // 사유 카드 아래 여백 추가
                    ],

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
      ),
    );
  }

  void _handleBackNavigation() {
    // recommendationReason이 있으면 온보딩을 통해 온 것이므로 홈으로 이동
    if (widget.recommendationReason != null) {
      context.go('/home');
    } else {
      Navigator.pop(context);
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _handleBackNavigation,
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
                  child: Text('#$tag', style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationReason() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _spacingMedium),
      child: Container(
        padding: const EdgeInsets.all(_spacingMedium),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_borderRadius),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: _mainColor,
              size: 20,
            ),
            const SizedBox(width: _spacingSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '코스 추천 사유',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: _spacingSmall),
                  Text(
                    _recommendationReason!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    return Padding(
      key: _mapSectionKey,
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
                onMapTapped: (point, latLng) {
                  _handleMapTap(latLng);
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
          key: _setCardKeys[set.setId],
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
              GestureDetector(
                onTap: () => _moveToMarker(set.setId),
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        set.setAddress,
                        style: TextStyle(
                          color: _mainColor,
                        ),
                      ),
                    ),
                  ],
                ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: _spacingMedium,
        vertical: _spacingSmall,
      ),
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
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _commentController,
                  maxLength: _maxCommentLength,
                  maxLines: 1,
                  decoration: InputDecoration(
                    hintText: '댓글 작성',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_borderRadius),
                    ),
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: _spacingSmall),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: !_isCommentInputEmpty
                    ? () => _submitComment()
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('댓글', style: TextStyle(fontSize: 12)),
              ),
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

