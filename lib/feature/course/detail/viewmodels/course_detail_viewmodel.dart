import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/feature/course/models/course_detail_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CourseDetailViewModel extends ChangeNotifier {
  CourseDetail? _courseDetail;
  bool _isLoading = false;
  String? _errorMessage;

  bool _isLiked = false;
  int _likeCount = 0;
  List<Comment> _comments = [];

  final int courseId;
  final String userId;
  final String? recommendationReason;

  CourseDetail? get courseDetail => _courseDetail;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLiked => _isLiked;
  int get likeCount => _likeCount;
  List<Comment> get comments => _comments;

  CourseDetailViewModel({
    required this.courseId,
    required this.userId,
    this.recommendationReason,
  });

  Future<void> loadCourseDetail() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 코스 디테일을 먼저 가져오기
      final data = await SupabaseManager.shared.getCourseDetail(
        courseId,
        userId,
      );

      if (data == null) {
        _isLoading = false;
        _errorMessage = 'data null';
        notifyListeners();
        return;
      }

      final courseDetail = CourseDetail.fromJson(data);

      // 코스 정보를 먼저 표시 (점진적 로딩)
      _courseDetail = courseDetail;
      _comments = List.from(courseDetail.comments);
      _isLoading = false;
      notifyListeners();

      // 좋아요 정보는 백그라운드에서 가져와서 업데이트
      _loadLikeInfo().then((likeInfo) {
        _isLiked = likeInfo['isLiked'] as bool;
        _likeCount = likeInfo['likeCount'] as int;
        notifyListeners();
      }).catchError((e) {
        debugPrint('좋아요 정보 로드 오류: $e');
        // 좋아요 정보 로드 실패해도 기본값으로 계속 진행
        _isLiked = false;
        _likeCount = 0;
        notifyListeners();
      });
    } catch (e, st) {
      debugPrint('코스 디테일 로드 오류: $e');
      debugPrint('스택 트레이스: $st');
      _isLoading = false;
      _errorMessage = e.toString();
      _isLiked = false;
      _likeCount = 0;
      _comments = [];
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> _loadLikeInfo() async {
    try {
      final supabase = SupabaseManager.shared.supabase;

      // 한 번의 쿼리로 좋아요 개수와 사용자 좋아요 여부를 모두 가져오기
      final likedCourses = await supabase
          .from('liked_courses')
          .select('user_id')
          .eq('course_id', courseId);

      final likeList = likedCourses as List;
      final likeCount = likeList.length;

      // 사용자 좋아요 여부 확인 (메모리에서 필터링)
      bool isLiked = false;
      if (userId.isNotEmpty) {
        isLiked = likeList.any((item) => item['user_id'] == userId);
      }

      return {'likeCount': likeCount, 'isLiked': isLiked};
    } catch (e) {
      debugPrint('좋아요 정보 가져오기 오류: $e');
      return {'likeCount': 0, 'isLiked': false};
    }
  }

  Future<void> toggleLike() async {
    final userRowId = await SupabaseManager.shared.getMyUserRowId();
    if (userRowId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    try {
      final supabase = SupabaseManager.shared.supabase;

      if (_isLiked) {
        await supabase
            .from('liked_courses')
            .delete()
            .eq('course_id', courseId)
            .eq('user_id', userRowId);
        await _updateLearningData(supabase, userRowId, courseId, 0);
      } else {
        await supabase.from('liked_courses').insert({
          'course_id': courseId,
          'user_id': userRowId,
        });
        await _updateLearningData(supabase, userRowId, courseId, 1);
      }

      final likeInfo = await _loadLikeInfo();
      _isLiked = likeInfo['isLiked'] as bool;
      _likeCount = likeInfo['likeCount'] as int;
      notifyListeners();
    } catch (e) {
      debugPrint('좋아요 처리 오류: $e');
      rethrow;
    }
  }

  Future<void> _updateLearningData(
    SupabaseClient supabase,
    String userId,
    int courseId,
    int label,
  ) async {
    try {
      final courseData = await supabase
          .from('courses')
          .select('title')
          .eq('id', courseId)
          .maybeSingle();

      final courseTitle = courseData?['title'] as String? ?? '';

      final existingData = await supabase
          .from('learningData')
          .select('id')
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .maybeSingle();

      if (existingData != null) {
        await supabase
            .from('learningData')
            .update({'label': label})
            .eq('id', existingData['id']);
      } else {
        await supabase.from('learningData').insert({
          'user_id': userId,
          'course_id': courseId,
          'label': label,
          'title': courseTitle,
        });
      }
    } catch (e) {
      debugPrint('learningData 업데이트 오류: $e');
    }
  }

  Future<void> submitComment(String commentText) async {
    final userRowId = await SupabaseManager.shared.getMyUserRowId();
    if (userRowId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    try {
      final supabase = SupabaseManager.shared.supabase;

      final response = await supabase
          .from('comments')
          .insert({
        'course_id': courseId,
        'user_id': userRowId,
        'comment': commentText,
      })
          .select('''
        *,
        user:users!comments_user_id_fkey(nickname, profile_img)
      ''')
          .single();

      final user = response['user'] ?? {};
      final newComment = Comment(
        commentId: response['id'].toString(),
        commentAuthor: user['nickname'] ?? '',
        commentAvatar: user['profile_img'] ?? '',
        commentBody: response['comment'] ?? '',
        commentTime: DateTime.parse(response['created_at']),
        isCommentAuthor: true,
      );

      _comments.add(newComment);
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('댓글 작성 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      final supabase = SupabaseManager.shared.supabase;

      await supabase
          .from('comments')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', int.parse(commentId))
          .select();

      _comments.removeWhere((c) => c.commentId == commentId);
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('댓글 삭제 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  Future<void> deleteCourse() async {
    try {
      final supabase = SupabaseManager.shared.supabase;

      final courseData = await supabase
          .from('courses')
          .select('set_01, set_02, set_03, set_04, set_05')
          .eq('id', courseId)
          .maybeSingle();

      if (courseData == null) {
        debugPrint('코스 데이터를 찾을 수 없음');
        return;
      }

      final setIds = [
        courseData['set_01'],
        courseData['set_02'],
        courseData['set_03'],
        courseData['set_04'],
        courseData['set_05'],
      ].where((id) => id != null).toList();

      List<Map<String, dynamic>> setRows = [];
      if (setIds.isNotEmpty) {
        setRows = await supabase
            .from('course_sets')
            .select('img_01, img_02, img_03')
            .inFilter('id', setIds);
      }

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
            debugPrint("이미지 삭제 실패: $e");
          }
        }
      }

      await supabase.from('comments').delete().eq('course_id', courseId);
      await supabase.from('liked_courses').delete().eq('course_id', courseId);

      for (final setId in setIds) {
        await supabase.from('course_sets').delete().eq('id', setId);
      }

      await supabase.from('courses').delete().eq('id', courseId);
    } catch (e, st) {
      debugPrint('코스 삭제 오류: $e');
      debugPrint('스택트레이스: $st');
      rethrow;
    }
  }
}

