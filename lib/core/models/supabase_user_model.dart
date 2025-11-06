class SupabaseUserModel {
  final String email;
  final String? profile_img;
  final String nickname;

  // bool get isMine {
  //   final String? currentUserId =
  //       SupabaseManager.shared.supabase.auth.currentUser?.id;
  //
  //   if (currentUserId == null) {
  //     return false;
  //   }
  //   return currentUserId == sender_id;
  // }

  SupabaseUserModel({
    required this.email,
    required this.profile_img,
    required this.nickname,
  });

  // json -> ChatMessage
  factory SupabaseUserModel.fromJson(Map<String, dynamic> json) {
    return SupabaseUserModel(
      email: json["email"] as String,
      profile_img: json["profile_img"] as String?,
      nickname: json["nickname"] as String,
    );
  }
}

// Map<String, dynamic> = json
