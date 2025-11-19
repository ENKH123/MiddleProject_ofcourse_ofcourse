import 'package:supabase_flutter/supabase_flutter.dart';

class AuthDataSource {
  AuthDataSource._();
  static final AuthDataSource instance = AuthDataSource._();

  final supabase = Supabase.instance.client;

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
}
