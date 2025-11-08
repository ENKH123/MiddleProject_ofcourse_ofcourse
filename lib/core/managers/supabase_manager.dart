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

  // 코스 상세 정보 가져오기
  Future<Map<String, dynamic>?> getCourseDetail(int courseId, String? currentUserId) async {
    // 코스 기본 정보 가져오기
    final course = await supabase
        .from('courses')
        .select('''
          *,
          author:users!courses_author_id_fkey(nickname, profile_img)
        ''')
        .eq('id', courseId)
        .maybeSingle();

    if (course == null) return null;

    // 코스 세트들 가져오기 (created_at 순서로)
    final sets = await supabase
        .from('course_sets')
        .select('''
          *,
          tag_info:tags!course_sets_tag_fkey(id, type)
        ''')
        .eq('course_id', courseId)
        .order('created_at', ascending: true);

    // 세트 데이터 변환
    final List<Map<String, dynamic>> processedSets = [];
    final Set<String> allTags = {}; // 전체 태그 수집용

    for (var set in sets) {
      // 이미지 배열 생성 (null 제외)
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

      // 태그 이름 수집
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

    // 댓글 가져오기 (deleted_at이 null인 것만, 최대 50개)
    final allComments = await supabase
        .from('comments')
        .select('''
          *,
          user:users!comments_user_id_fkey(nickname, profile_img)
        ''')
        .eq('course_id', courseId)
        .order('created_at', ascending: false)
        .limit(50);

    // deleted_at이 null인 댓글만 필터링
    final comments = (allComments as List)
        .where((comment) => comment['deleted_at'] == null)
        .toList();

    // 댓글 데이터 변환
    final List<Map<String, dynamic>> processedComments = [];
    for (var comment in comments) {
      final user = comment['user'] as Map<String, dynamic>?;
      processedComments.add({
        'id': comment['id'],
        'author': user?['nickname'] ?? '',
        'avatar': user?['profile_img'] ?? '',
        'body': comment['comment'] ?? '',
        'time': comment['created_at'],
        'is_author': comment['user_id'] == currentUserId,
      });
    }

    // 작성자 정보
    final author = course['author'] as Map<String, dynamic>?;

    return {
      'id': course['id'],
      'title': course['title'] ?? '',
      'marker_image': course['marker_image'] ?? '',
      'author_name': author?['nickname'] ?? '',
      'author_profile': author?['profile_img'] ?? '',
      'tags': allTags.toList(), // 중복 제거된 태그 목록
      'sets': processedSets,
      'created_at': course['created_at'],
      'is_author': course['author_id'] == currentUserId,
      // TODO: liked_courses 테이블에서 좋아요 개수 및 사용자 좋아요 여부 조회
      'like_count': 0,
      'is_liked': false,
      'comment_count': processedComments.length,
      'comments': processedComments,
    };
  }
}
