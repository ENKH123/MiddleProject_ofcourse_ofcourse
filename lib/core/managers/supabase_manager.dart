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
}
