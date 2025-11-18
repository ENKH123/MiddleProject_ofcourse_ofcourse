import 'package:flutter/material.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/supabase_user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileViewModel extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  SupabaseUserModel? user;
  bool isLoading = false;

  String? _loadedEmail;

  Future<void> loadUser() async {
    final currentEmail = supabase.auth.currentUser?.email;

    // 로그인 안 되어 있으면 상태 초기화
    if (currentEmail == null) {
      user = null;
      _loadedEmail = null;
      isLoading = false;
      notifyListeners();
      return;
    }

    if (_loadedEmail == currentEmail && user != null) {
      return;
    } // 이미 같은 이메일로 로딩된 상태면 다시 안 불러와도 됨

    isLoading = true;
    notifyListeners();

    user = await SupabaseManager.shared.fetchPublicUser(currentEmail);
    _loadedEmail = currentEmail;

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

  void clear() {
    user = null;
    _loadedEmail = null;
    isLoading = false;
    notifyListeners();
  }
}
