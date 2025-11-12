import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:of_course/core/models/gu_model.dart';
import 'package:of_course/core/models/supabase_user_model.dart';
import 'package:of_course/core/models/tags_moedl.dart';
import 'package:of_course/feature/report/models/report_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseManager {
  static final SupabaseManager _shared = SupabaseManager();

  static SupabaseManager get shared => _shared;

  // Get a reference your Supabase client
  final supabase = Supabase.instance.client;

  SupabaseManager() {
    debugPrint("SupabaseManager init");
  }

  // 회원가입 여부 검증
  Future<SupabaseUserModel?> getPublicUser(String gmail) async {
    final Map<String, dynamic>? data = await supabase
        .from("users")
        .select()
        .eq('email', gmail)
        .maybeSingle();
    if (data == null) {
      return null;
    }
    return SupabaseUserModel.fromJson(data);
  }

  // 회원탈퇴
  Future<void> resign() async {
    // 현재 로그인 정보
    final currentUser = supabase.auth.currentUser;

    if (currentUser != null) {
      // 프로필 사진 url 가져오기
      final Map<String, dynamic>? urlResult = await supabase
          .from('users')
          .select('profile_img')
          .eq('email', currentUser.email ?? "")
          .maybeSingle();

      // 프로필 사진 url 정보만 담기
      final String? publicUrl = urlResult?['profile_img'].toString();

      // bucket 파일 삭제
      if (publicUrl != "null") {
        final String baseUrl =
            'https://dbhecolzljfrmgtdjwie.supabase.co/storage/v1/object/public/profile/';
        final String filePath = publicUrl?.substring(baseUrl.length) ?? "";
        await supabase.storage.from('profile').remove([filePath]);
      }
      // 계정 삭제
      await supabase
          .from("users")
          .delete()
          .eq('email', currentUser.email ?? "");
    }
  }

  // 구 목록 가져오기
  Future<List<GuModel>> getGuList() async {
    final data = await supabase.from("gu").select();
    return (data as List).map((e) => GuModel.fromJson(e)).toList();
  }

  //  태그 목록 가져오기
  Future<List<TagModel>> getTags() async {
    final data = await supabase.from("tags").select();
    return (data as List).map((e) => TagModel.fromJson(e)).toList();
  }

  // 회원가입 계정 생성
  Future<void> createUserProfile(
    String userEmail,
    String userNickname, [
    String? userProfileImage,
  ]) async {
    await supabase.from('users').insert({
      'email': userEmail,
      'nickname': userNickname,
      'profile_img': userProfileImage,
    });
  }

  // 닉네임 중복 여부 검증
  Future<bool> isDuplicatedNickname(String value) async {
    final Map<String, dynamic>? isDuplicated = await supabase
        .from("users")
        .select()
        .eq('nickname', value)
        .maybeSingle();

    return isDuplicated == null ? true : false;
  }

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
    required String address,
    required double lat,
    required double lng,
    int? tagId,
    int? gu,
    String? description,
  }) async {
    try {
      final inserted = await supabase
          .from('course_sets')
          .insert({
            'img_01': img1,
            'img_02': img2,
            'img_03': img3,
            'address': address,
            'lat': lat,
            'lng': lng,
            'tag': tagId,
            'gu': gu,
            'description': description,
          })
          .select()
          .single();
      return inserted['id'] as int;
    } catch (e) {
      debugPrint('insertCourseSet error: $e');
      return null;
    }
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

  //기본 코스 가져오기
  Future<List<Map<String, dynamic>>> getCourseList({
    int? guId,
    List<String>? selectedTagNames,
  }) async {
    final supabase = Supabase.instance.client;

    final courses = await supabase
        .from('courses')
        .select('*')
        .eq('is_done', true)
        .order('created_at', ascending: false);

    List<Map<String, dynamic>> result = [];

    for (final course in courses) {
      final courseId = course['id'];

      // 구 비교: set_01 의 gu만 비교
      if (guId != null && course['set_01'] != null) {
        final set1 = await supabase
            .from('course_sets')
            .select('gu')
            .eq('id', course['set_01'])
            .maybeSingle();

        if (set1 == null || set1['gu'] != guId) {
          continue; // 구가 다르면 이 코스 제외
        }
      }

      //  세트 ID 수집
      final setIds = [
        course['set_01'],
        course['set_02'],
        course['set_03'],
        course['set_04'],
        course['set_05'],
      ].where((id) => id != null).toList();

      if (setIds.isEmpty) continue;

      // 세트 조회 (구 필터 없음)
      final sets = await supabase
          .from('course_sets')
          .select('img_01, img_02, img_03, tag, tags(type)')
          .filter('id', 'in', '(${setIds.join(',')})');

      //  이미지 3장 추출
      final List<String> imageCandidates = [];
      for (final s in sets) {
        for (final img in [s['img_01'], s['img_02'], s['img_03']]) {
          if (img != null && img.toString().isNotEmpty) {
            imageCandidates.add(img.toString());
          }
        }
      }
      final images = imageCandidates.take(3).toList();

      // 태그 수집
      final tags = <String>{};
      for (final s in sets) {
        final tag = s['tags']?['type'];
        if (tag != null) tags.add(tag);
      }

      //  태그 필터 적용 (선택된 태그 중 하나라도 포함되지 않으면 skip)
      if (selectedTagNames != null && selectedTagNames.isNotEmpty) {
        final intersects = tags.intersection(selectedTagNames.toSet());
        if (intersects.isEmpty) continue;
      }

      result.add({
        'id': courseId,
        'title': course['title'],
        'images': images,
        'tags': tags.toList(),
        'like_count': 0,
        'comment_count': 0,
      });
    }

    return result;
  }

  //좋아요한 코스 가져오기
  Future<List<Map<String, dynamic>>> getLikedCourses({
    List<String>? selectedTagNames,
  }) async {
    final userRowId = await getMyUserRowId();
    if (userRowId == null) return [];

    final liked = await supabase
        .from('liked_courses')
        .select('course_id')
        .eq('user_id', userRowId);

    final likedCourseIds = (liked as List)
        .map((e) => e['course_id'] as int)
        .toList();

    if (likedCourseIds.isEmpty) return [];

    final courses = await supabase
        .from('courses')
        .select('*')
        .inFilter('id', likedCourseIds)
        .order('created_at', ascending: false);

    List<Map<String, dynamic>> result = [];

    for (final course in courses) {
      final setIds = [
        course['set_01'],
        course['set_02'],
        course['set_03'],
        course['set_04'],
        course['set_05'],
      ].where((id) => id != null).toList();

      if (setIds.isEmpty) continue;

      final sets = await supabase
          .from('course_sets')
          .select('img_01, img_02, img_03, tag, tags(type)')
          .filter('id', 'in', '(${setIds.join(',')})');

      final List<String> images = [];
      final Set<String> tags = {};

      for (final s in sets) {
        for (final img in [s['img_01'], s['img_02'], s['img_03']]) {
          if (img != null && img.toString().isNotEmpty) {
            images.add(img.toString());
          }
        }
        if (s['tags']?['type'] != null) {
          tags.add(s['tags']['type']);
        }
      }

      if (selectedTagNames != null && selectedTagNames.isNotEmpty) {
        if (tags.intersection(selectedTagNames.toSet()).isEmpty) continue;
      }

      result.add({
        'id': course['id'],
        'title': course['title'],
        'images': images.take(3).toList(),
        'tags': tags.toList(),
        'like_count': 0,
        'comment_count': 0,
      });
    }

    return result;
  }

  //내가 쓴 코스 가져오기
  Future<List<Map<String, dynamic>>> getMyCourses(String userId) async {
    final courses = await supabase
        .from('courses')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    List<Map<String, dynamic>> result = [];

    for (final course in courses) {
      final setIds = [
        course['set_01'],
        course['set_02'],
        course['set_03'],
        course['set_04'],
        course['set_05'],
      ].where((id) => id != null).toList();

      if (setIds.isEmpty) continue;

      final sets = await supabase
          .from('course_sets')
          .select('img_01, img_02, img_03, tags(type)')
          .filter('id', 'in', '(${setIds.join(',')})');

      final List<String> images = [];
      final Set<String> tags = {};

      for (final s in sets) {
        for (final img in [s['img_01'], s['img_02'], s['img_03']]) {
          if (img != null && img.toString().isNotEmpty) {
            images.add(img.toString());
          }
        }
        final tag = s['tags']?['type'];
        if (tag != null) tags.add(tag);
      }

      result.add({
        'id': course['id'],
        'title': course['title'],
        'images': images.take(3).toList(),
        'tags': tags.toList(),
      });
    }

    return result;
  }

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

  //로그인한 유저의 user.id 가져오기
  Future<String?> getMyUserRowId() async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) return null;

    final email = authUser.email;
    if (email == null) return null;

    final data = await supabase
        .from("users")
        .select("id")
        .eq("email", email)
        .maybeSingle();

    return data?['id'] as String?;
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
        .order('created_at', ascending: false)
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
      'like_count': 0, // TODO: 좋아요 수 연동 시 변경
      'is_liked': false, // TODO: 좋아요 상태 연동 시 변경
      'comment_count': processedComments.length,
      'comments': processedComments,
    };
  }

  // 신고 제출
  Future<void> submitReport({
    required String targetId,
    required ReportTargetType targetType,
    required ReportReason reportReason,
    required String reason,
    required List<String> imagePaths,
  }) async {
    try {
      // 현재 사용자 ID 가져오기
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 이미지 업로드 및 URL 가져오기
      final List<String> imageUrls = [];
      for (int i = 0; i < imagePaths.length && i < 3; i++) {
        final imageFile = File(imagePaths[i]);
        if (await imageFile.exists()) {
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final filePath = '$userId/$fileName';

          // Supabase Storage에 이미지 업로드
          await supabase.storage.from('reports').upload(filePath, imageFile);

          // 공개 URL 가져오기
          final imageUrl = supabase.storage
              .from('reports')
              .getPublicUrl(filePath);

          imageUrls.add(imageUrl);
        }
      }

      // target_type을 문자열로 변환
      final targetTypeString = targetType == ReportTargetType.course
          ? 'course'
          : 'comment';

      // 신고 데이터 삽입
      await supabase.from('reports').insert({
        'user_id': userId, // 신고를 제출한 사용자 ID
        'target_id': targetId,
        'target_type': targetTypeString,
        'report_type': reportReason.label,
        'reason': reason,
        'img_01': imageUrls.isNotEmpty ? imageUrls[0] : null,
        'img_02': imageUrls.length > 1 ? imageUrls[1] : null,
        'img_03': imageUrls.length > 2 ? imageUrls[2] : null,
      });
    } catch (e) {
      debugPrint('신고 제출 오류: $e');
      rethrow;
    }
  }

  // 좋아요한 코스 ID 목록 가져오기
  Future<List<int>> getLikedCourseIds(String userId) async {
    try {
      final likedCourses = await supabase
          .from('liked_courses')
          .select('course_id')
          .eq('user_id', userId);

      return (likedCourses as List)
          .map((item) => item['course_id'] as int)
          .toList();
    } catch (e) {
      debugPrint('좋아요한 코스 목록 가져오기 오류: $e');
      return [];
    }
  }

  // 태그 기반 랜덤 코스 가져오기
  Future<int?> getRandomCourseByTags(
    List<String> tagNames,
    List<int> excludeCourseIds,
  ) async {
    try {
      // 태그 이름으로 태그 ID 찾기 (각 태그에 대해 개별 쿼리)
      final List<int> tagIds = [];
      for (final tagName in tagNames) {
        final tag = await supabase
            .from('tags')
            .select('id')
            .eq('type', tagName)
            .maybeSingle();
        if (tag != null) {
          tagIds.add(tag['id'] as int);
        }
      }

      if (tagIds.isEmpty) return null;

      // 해당 태그를 가진 코스 세트 찾기 (각 태그 ID에 대해 개별 쿼리)
      final Set<int> courseIdSet = {};
      for (final tagId in tagIds) {
        final sets = await supabase
            .from('course_sets')
            .select('course_id')
            .eq('tag', tagId);
        for (final set in sets as List) {
          courseIdSet.add(set['course_id'] as int);
        }
      }

      if (courseIdSet.isEmpty) return null;

      // 제외할 코스 ID 필터링
      final courseIds = courseIdSet
          .where((id) => !excludeCourseIds.contains(id))
          .toList();

      if (courseIds.isEmpty) return null;

      // 랜덤으로 하나 선택
      courseIds.shuffle();
      return courseIds.first;
    } catch (e) {
      debugPrint('태그 기반 랜덤 코스 가져오기 오류: $e');
      return null;
    }
  }

  // 완전 랜덤 코스 가져오기
  Future<int?> getRandomCourse({required List<int> excludeCourseIds}) async {
    try {
      // 모든 코스 가져오기
      final courses = await supabase.from('courses').select('id');

      if (courses.isEmpty) return null;

      // 제외할 코스 ID 필터링
      final availableCourseIds = (courses as List)
          .map((course) => course['id'] as int)
          .where((id) => !excludeCourseIds.contains(id))
          .toList();

      if (availableCourseIds.isEmpty) return null;

      // 랜덤으로 하나 선택
      availableCourseIds.shuffle();
      return availableCourseIds.first;
    } catch (e) {
      debugPrint('랜덤 코스 가져오기 오류: $e');
      return null;
    }
  }
}
