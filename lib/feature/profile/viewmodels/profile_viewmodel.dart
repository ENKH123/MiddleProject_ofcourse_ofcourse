import 'package:flutter/material.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/supabase_user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileViewModel extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  SupabaseUserModel? user;
  bool isLoading = false;

  Future<void> loadUser() async {
    isLoading = true;
    notifyListeners();

    final email = supabase.auth.currentUser?.email;
    if (email != null) {
      user = await SupabaseManager.shared.fetchPublicUser(email);
    }

    isLoading = false;
    notifyListeners();
  }

  /// URL 변환 (경로 → URL)
  String? getProfileImageUrl() {
    final raw = user?.profile_img;
    if (raw == null) return null;

    if (raw.startsWith('http')) return raw;

    return supabase.storage.from('profile').getPublicUrl(raw);
  }
}
