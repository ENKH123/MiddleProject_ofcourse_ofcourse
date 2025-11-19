import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:of_course/core/data/core_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CourseDataSource {
  CourseDataSource._();
  static final CourseDataSource instance = CourseDataSource._();

  final supabase = Supabase.instance.client;

  // 이미지 업로드 (세트 이미지용)
  Future<String?> uploadCourseSetImage(File file) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

      final filePath = 'course_set/$fileName';

      await supabase.storage
          .from('course_set_image')
          .upload(
            filePath,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              contentType: 'image/jpeg',
            ),
          );

      return supabase.storage.from('course_set_image').getPublicUrl(filePath);
    } catch (e) {
      debugPrint('Course set image upload error: $e');
      return null;
    }
  }

  //  세트 DB 삽입
  Future<int?> insertCourseSet({
    String? img1,
    String? img2,
    String? img3,
    String? address,
    double? lat,
    double? lng,
    int? gu,
    int? tagId,
    String? description,
  }) async {
    final result = await supabase.from('course_sets').insert({
      'img_01': img1,
      'img_02': img2,
      'img_03': img3,
      'address': address,
      'lat': lat,
      'lng': lng,
      'gu': gu,
      'tag': tagId,
      'description': description,
    }).select();

    if (result.isNotEmpty) {
      return result[0]['id'] as int?;
    }
    return null;
  }

  //주소 가져와서 지역비교 후 지역id부여
  Future<int?> getGuIdFromName(String guName) async {
    // 공백 제거
    guName = guName.replaceAll(" ", "").replaceAll("시", "").replaceAll("청", "");

    final guList = await supabase.from('gu').select('id, gu_name');

    for (final row in guList) {
      final dbGuName = row['gu_name']
          .toString()
          .replaceAll(" ", "")
          .replaceAll("시", "")
          .replaceAll("청", "");

      if (guName.contains(dbGuName) || dbGuName.contains(guName)) {
        return row['id'] as int;
      }
    }

    return null;
  }

  //임시저장된 코스 확인
  Future<List<Map<String, dynamic>>> getDraftCourses(String userId) async {
    final result = await supabase
        .from('courses')
        .select('*')
        .eq('user_id', userId)
        .eq('is_done', false)
        .order('updated_at', ascending: false);

    return result;
  }

  // 특정 코스의 좋아요 개수 + 댓글 개수 가져오기
  Future<Map<String, int>> getCourseCount(int courseId) async {
    try {
      // 좋아요 개수
      final likeRows = await supabase
          .from('liked_courses')
          .select('user_id')
          .eq('course_id', courseId);

      final likeCount = (likeRows as List).length;

      // 댓글 개수 (deleted_at 제외)
      final commentRows = await supabase
          .from('comments')
          .select('id')
          .eq('course_id', courseId)
          .isFilter('deleted_at', null);

      final commentCount = (commentRows as List).length;

      return {'like_count': likeCount, 'comment_count': commentCount};
    } catch (e) {
      debugPrint("getCourseStats error: $e");
      return {'like_count': 0, 'comment_count': 0};
    }
  }

  Future<List<Map<String, dynamic>>> getLikedCourses({
    List<String>? selectedTagNames,
  }) async {
    final userRowId = await CoreDataSource.instance.getMyUserRowId();
    if (userRowId == null) return [];

    // 사용자가 좋아요한 코스 ID 목록
    final likedRows = await supabase
        .from('liked_courses')
        .select('course_id')
        .eq('user_id', userRowId);

    final likedIds = (likedRows as List)
        .map((e) => e['course_id'] as int)
        .toList();

    if (likedIds.isEmpty) return [];

    // 좋아요한 코스들을 한 번에 JOIN으로 가져오기
    final rows = await supabase
        .from('courses')
        .select('''
        id, title, created_at,

        set_01:course_sets!courses_set_01_fkey (
          img_01, img_02, img_03, tag, tags(type)
        ),
        set_02:course_sets!courses_set_02_fkey (
          img_01, img_02, img_03, tag, tags(type)
        ),
        set_03:course_sets!courses_set_03_fkey (
          img_01, img_02, img_03, tag, tags(type)
        ),
        set_04:course_sets!courses_set_04_fkey (
          img_01, img_02, img_03, tag, tags(type)
        ),
        set_05:course_sets!courses_set_05_fkey (
          img_01, img_02, img_03, tag, tags(type)
        )
      ''')
        .inFilter('id', likedIds)
        .order('created_at', ascending: false);

    final List<Map<String, dynamic>> result = [];

    for (final c in rows as List) {
      final List<String> images = [];
      final Set<String> tags = {};

      for (final key in ['set_01', 'set_02', 'set_03', 'set_04', 'set_05']) {
        final set = c[key];
        if (set == null) continue;

        for (final img in [set['img_01'], set['img_02'], set['img_03']]) {
          if (img != null && img.toString().isNotEmpty) {
            images.add(img.toString());
          }
        }

        final tagInfo = set['tags'];
        if (tagInfo != null && tagInfo['type'] != null) {
          tags.add(tagInfo['type']);
        }
      }

      if (selectedTagNames != null && selectedTagNames.isNotEmpty) {
        if (tags.intersection(selectedTagNames.toSet()).isEmpty) continue;
      }

      final count = await getCourseCount(c['id']);

      result.add({
        'id': c['id'],
        'title': c['title'],
        'images': images.take(3).toList(),
        'tags': tags.toList(),
        'like_count': count['like_count'],
        'comment_count': count['comment_count'],
        'is_liked': true,
      });
    }

    return result;
  }

  //수정모드 코스 가져오기
  Future<Map<String, dynamic>?> getCourseForEdit(int courseId) async {
    final supabase = Supabase.instance.client;

    final course = await supabase
        .from('courses')
        .select('*')
        .eq('id', courseId)
        .maybeSingle();

    if (course == null) return null;

    final setKeys = ['set_01', 'set_02', 'set_03', 'set_04', 'set_05'];
    List<Map<String, dynamic>> sets = [];

    for (final key in setKeys) {
      final setId = course[key];
      if (setId == null) continue;

      final cs = await supabase
          .from('course_sets')
          .select('*')
          .eq('id', setId)
          .maybeSingle();

      if (cs == null) continue;

      sets.add({
        "id": cs['id'],
        "query": cs['address'] ?? "",
        "lat": cs['lat'],
        "lng": cs['lng'],
        "gu": cs['gu'],
        "tag_id": cs['tag'],
        "description": cs['description'] ?? "",
        "images": [
          cs['img_01'],
          cs['img_02'],
          cs['img_03'],
        ].where((e) => e != null && e.toString().isNotEmpty).toList(),
      });
    }

    return {"title": course['title'], "sets": sets};
  }

  Future<Map<String, dynamic>?> getCourseDetailForContinue(int courseId) async {
    final supabase = Supabase.instance.client;

    final course = await supabase
        .from('courses')
        .select('*')
        .eq('id', courseId)
        .maybeSingle();

    if (course == null) return null;

    final setKeys = ['set_01', 'set_02', 'set_03', 'set_04', 'set_05'];
    List<Map<String, dynamic>> sets = [];

    for (final key in setKeys) {
      final setId = course[key];
      if (setId == null) continue;

      final cs = await supabase
          .from('course_sets')
          .select('*')
          .eq('id', setId)
          .maybeSingle();

      if (cs == null) continue;

      sets.add({
        "id": cs['id'],
        "query": cs['address'] ?? "",
        "lat": cs['lat'],
        "lng": cs['lng'],
        "gu": cs['gu'],
        "tag_id": cs['tag'],
        "description": cs['description'] ?? "",
        "images": [
          cs['img_01'],
          cs['img_02'],
          cs['img_03'],
        ].where((e) => e != null && e.toString().isNotEmpty).toList(),
      });
    }

    return {"title": course['title'], "sets": sets};
  }

  // 코스 상세 정보 가져오기
  Future<Map<String, dynamic>?> getCourseDetail(
    int courseId,
    String? currentUserId,
  ) async {
    // 1) 코스 기본 정보 + 작성자 조인
    final course = await supabase
        .from('courses')
        .select('''
        *,
        author:users!courses_user_id_fkey(nickname, profile_img)
      ''')
        .eq('id', courseId)
        .maybeSingle();

    if (course == null) return null;

    // 2) 세트 ID 목록 추출 (null 제거)
    final List<int> setIds = [
      course['set_01'],
      course['set_02'],
      course['set_03'],
      course['set_04'],
      course['set_05'],
    ].where((id) => id != null).map((id) => id as int).toList();

    // 세트가 없다면 그냥 빈 리스트
    List<Map<String, dynamic>> sets = [];
    if (setIds.isNotEmpty) {
      sets = await supabase
          .from('course_sets')
          .select('''
          *,
          tag_info:tags!course_sets_tag_fkey(type)
        ''')
          .inFilter('id', setIds)
          .order('created_at', ascending: true);
    }

    // 세트 데이터 변환 + 태그 수집
    final List<Map<String, dynamic>> processedSets = [];
    final Set<String> allTags = {};

    for (var set in sets) {
      final List<String> images = [];

      for (final key in ['img_01', 'img_02', 'img_03']) {
        if (set[key] != null && (set[key] as String).isNotEmpty) {
          images.add(set[key]);
        }
      }

      if (set['tag_info'] != null) {
        allTags.add(set['tag_info']['type']);
      }

      processedSets.add({
        'id': set['id'],
        'images': images,
        'address': set['address'] ?? '',
        'description': set['description'] ?? '',
        'tag': set['tag_info']?['type'] ?? '',
        'lat': set['lat'],
        'lng': set['lng'],
      });
    }

    // 3) 댓글 가져오기
    final rawComments = await supabase
        .from('comments')
        .select('''
        *,
        user:users!comments_user_id_fkey(nickname, profile_img)
      ''')
        .eq('course_id', courseId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: true)
        .limit(50);

    final processedComments = (rawComments as List).map((comment) {
      final user = comment['user'] ?? {};
      return {
        'id': comment['id'],
        'user_id': comment['user_id'],
        'author': user['nickname'] ?? '',
        'avatar': user['profile_img'] ?? '',
        'body': comment['comment'] ?? '',
        'time': comment['created_at'], //
        'is_author': comment['user_id'] == currentUserId,
      };
    }).toList();

    return {
      'id': course['id'],
      'title': course['title'] ?? '',
      'marker_image': course['marker_image'] ?? '',
      'author_id': course['user_id'],
      'author_name': course['author']?['nickname'] ?? '',
      'author_profile': course['author']?['profile_img'] ?? '',
      'tags': allTags.toList(),
      'sets': processedSets,
      'created_at': course['created_at'].toString(), //
      'is_author': course['user_id'] == currentUserId,
      'comment_count': processedComments.length,
      'comments': processedComments,
    };
  }
}
