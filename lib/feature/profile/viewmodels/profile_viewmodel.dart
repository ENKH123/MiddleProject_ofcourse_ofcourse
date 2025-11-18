import 'package:flutter/material.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/supabase_user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileViewModel extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  SupabaseUserModel? user;
  bool isLoading = false;
  DateTime? lastBackPressTime;

  /// 현재 로그인한 유저 정보 로딩
  Future<void> loadUser({bool force = false}) async {
    final email = supabase.auth.currentUser?.email;

    // 로그인 안 되어 있으면 상태 초기화
    if (email == null) {
      user = null;
      isLoading = false;
      notifyListeners();
      return;
    }

    // 이미 같은 이메일의 유저를 갖고 있고, force가 아니면 그냥 리턴
    if (!force && user != null && user!.email == email) {
      return;
    }

    isLoading = true;
    notifyListeners();

    user = await SupabaseManager.shared.fetchPublicUser(email);

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

  /// 로그아웃 시 상태 비우고 싶을 때
  void clear() {
    user = null;
    isLoading = false;
    notifyListeners();
  }

  bool handleWillPop() {
    final now = DateTime.now();

    // 최초 클릭
    if (lastBackPressTime == null) {
      lastBackPressTime = now;
      return false;
    }

    // 2초 초과 → 다시 초기화
    if (now.difference(lastBackPressTime!) > const Duration(seconds: 2)) {
      lastBackPressTime = now;
      return false;
    }

    // 2초 이내 두 번째 클릭 → 종료
    return true;
  }
}
