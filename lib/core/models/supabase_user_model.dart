class SupabaseUserModel {
  final String email;
  final String? profile_img;
  final String nickname;

  SupabaseUserModel({
    required this.email,
    required this.profile_img,
    required this.nickname,
  });

  factory SupabaseUserModel.fromJson(Map<String, dynamic> json) {
    return SupabaseUserModel(
      email: json["email"] as String,
      profile_img: json["profile_img"] as String?,
      nickname: json["nickname"] as String,
    );
  }
}
