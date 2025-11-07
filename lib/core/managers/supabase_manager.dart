import 'package:flutter/cupertino.dart';
import 'package:of_course/core/models/supabase_user_model.dart';
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
