import 'package:flutter/cupertino.dart';
import 'package:of_course/core/models/supabase_user_model.dart';
import 'package:of_course/core/models/tags_moedl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';

class CoreDataSource {
  CoreDataSource._();
  static final CoreDataSource instance = CoreDataSource._();

  final suppbase = Supabase.instance.client;

  // 회원가입 여부 검증
  // 로그인 된 사용자의 정보 가져오기
  Future<SupabaseUserModel?> fetchPublicUser(String gmail) async {
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

  //  태그 목록 가져오기
  Future<List<TagModel>> getTags() async {
    final data = await supabase.from("tags").select();
    return (data as List).map((e) => TagModel.fromJson(e)).toList();
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

  Future<int?> getRandomCourseByTags(
    List<String> tagNames,
    List<int> excludeCourseIds,
  ) async {
    try {
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

      final courseIds = courseIdSet
          .where((id) => !excludeCourseIds.contains(id))
          .toList();

      if (courseIds.isEmpty) return null;

      courseIds.shuffle();
      return courseIds.first;
    } catch (e) {
      debugPrint('태그 기반 랜덤 코스 가져오기 오류: $e');
      return null;
    }
  }

  Future<int?> getRandomCourse({required List<int> excludeCourseIds}) async {
    try {
      final courses = await supabase.from('courses').select('id');

      if (courses.isEmpty) return null;

      final availableCourseIds = (courses as List)
          .map((course) => course['id'] as int)
          .where((id) => !excludeCourseIds.contains(id))
          .toList();

      if (availableCourseIds.isEmpty) return null;

      availableCourseIds.shuffle();
      return availableCourseIds.first;
    } catch (e) {
      debugPrint('랜덤 코스 가져오기 오류: $e');
      return null;
    }
  }
}
