import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:of_course/core/models/gu_model.dart';
import 'package:of_course/core/models/supabase_user_model.dart';
import 'package:of_course/core/models/tags_moedl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseManager {
  static final SupabaseManager _shared = SupabaseManager();
  static SupabaseManager get shared => _shared;

  // Get a reference your Supabase client
  final supabase = Supabase.instance.client;

  SupabaseManager() {
    debugPrint("SupabaseManager init");
  }
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

  Future<void> createUserProfile(String userEmail, String userNickname) async {
    await supabase.from('users').insert({
      'email': userEmail,
      'nickname': userNickname,
    });
  }

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

      await supabase.storage.from('course_set_image').upload(fileName, file);

      return supabase.storage.from('course_set_image').getPublicUrl(fileName);
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
}
