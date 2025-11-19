import 'package:of_course/core/data/core_data_source.dart';
import 'package:of_course/feature/home/models/gu_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeDataSource {
  HomeDataSource._();
  static final HomeDataSource instance = HomeDataSource._();
  final supabase = Supabase.instance.client;

  // 구 목록 가져오기
  Future<List<GuModel>> getGuList() async {
    final data = await supabase.from("gu").select();
    return (data as List).map((e) => GuModel.fromJson(e)).toList();
  }

  //기본 코스 가져오기
  Future<List<Map<String, dynamic>>> getCourseList({
    int? guId,
    List<String>? selectedTagNames,
  }) async {
    final supabase = Supabase.instance.client;

    //  코스 전체 먼저 가져오기
    final courses = await supabase
        .from('courses')
        .select('*')
        .eq('is_done', true)
        .order('created_at', ascending: false);

    if (courses.isEmpty) return [];

    // 2모든 코스의 setId를 한 번에 수집

    final List<int> allSetIds = [];
    for (final c in courses) {
      for (final key in ['set_01', 'set_02', 'set_03', 'set_04', 'set_05']) {
        if (c[key] != null) allSetIds.add(c[key]);
      }
    }

    if (allSetIds.isEmpty) return [];

    // 3 모든 세트를 한 번에 가져오기

    final allSets = await supabase
        .from('course_sets')
        .select('id, img_01, img_02, img_03, tag, gu, tags(type)')
        .inFilter('id', allSetIds);

    final Map<int, Map<String, dynamic>> setById = {
      for (final s in allSets) s['id'] as int: s,
    };

    final filteredCourses = courses.where((course) {
      if (guId == null) return true;

      final firstId = course['set_01'];
      if (firstId == null) return false;

      final set1 = setById[firstId];
      if (set1 == null) return false;

      return set1['gu'] == guId;
    }).toList();

    if (filteredCourses.isEmpty) return [];

    final List<int> courseIds = filteredCourses
        .map((c) => c['id'] as int)
        .toList();

    final likedRows = await supabase
        .from('liked_courses')
        .select('course_id')
        .inFilter('course_id', courseIds);

    final Map<int, int> likeCountMap = {};
    for (final row in likedRows) {
      final cid = row['course_id'] as int;
      likeCountMap[cid] = (likeCountMap[cid] ?? 0) + 1;
    }

    final commentRows = await supabase
        .from('comments')
        .select('course_id')
        .inFilter('course_id', courseIds)
        .isFilter('deleted_at', null);

    final Map<int, int> commentCountMap = {};
    for (final row in commentRows) {
      final cid = row['course_id'] as int;
      commentCountMap[cid] = (commentCountMap[cid] ?? 0) + 1;
    }

    final userId = await CoreDataSource.instance.getMyUserRowId();
    Set<int> likedCourseIds = {};

    if (userId != null) {
      final liked = await supabase
          .from('liked_courses')
          .select('course_id')
          .eq('user_id', userId)
          .inFilter('course_id', courseIds);

      likedCourseIds = liked.map((row) => row['course_id'] as int).toSet();
    }

    List<Map<String, dynamic>> result = [];

    for (final course in filteredCourses) {
      final courseId = course['id'] as int;

      // 세트 이미지 3장 수집
      final List<String> images = [];
      for (final key in ['set_01', 'set_02', 'set_03', 'set_04', 'set_05']) {
        final sid = course[key];
        if (sid == null) continue;

        final set = setById[sid];
        if (set == null) continue;

        for (final img in [set['img_01'], set['img_02'], set['img_03']]) {
          if (img != null && img.toString().isNotEmpty) {
            images.add(img.toString());
          }
        }
      }

      // 태그 수집
      final Set<String> tags = {};
      for (final key in ['set_01', 'set_02', 'set_03', 'set_04', 'set_05']) {
        final sid = course[key];
        if (sid == null) continue;
        final set = setById[sid];
        final tagInfo = set?['tags'];
        if (tagInfo != null && tagInfo['type'] != null) {
          tags.add(tagInfo['type']);
        }
      }

      // 태그 필터 적용
      if (selectedTagNames != null && selectedTagNames.isNotEmpty) {
        if (tags.intersection(selectedTagNames.toSet()).isEmpty) continue;
      }

      result.add({
        'id': courseId,
        'title': course['title'],
        'images': images.take(3).toList(),
        'tags': tags.toList(),
        'like_count': likeCountMap[courseId] ?? 0,
        'comment_count': commentCountMap[courseId] ?? 0,
        'is_liked': likedCourseIds.contains(courseId),
      });
    }

    return result;
  }
}
