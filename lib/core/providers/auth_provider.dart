import 'package:flutter/cupertino.dart';
import 'package:gotrue/src/types/user.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/main.dart';

import '../models/supabase_user_model.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  User? get currentUser => _currentUser;

  SupabaseUserModel? _user;
  SupabaseUserModel? get user => _user;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchCurrentUser();
    if (_currentUser != null) {
      await _fetchUser();
    }
    if (_currentUser != null && _user != null) {
      _isInitialized = true;
    }
    notifyListeners();
  }

  // 로그인 세션 가져오기
  Future<void> _fetchCurrentUser() async {
    _currentUser = supabase.auth.currentUser;
  }

  // 세션의 이메일이 실제 테이블에 있는지 추가 검증하여 예외 처리
  Future<void> _fetchUser() async {
    _user = await SupabaseManager.shared.fetchPublicUser(_currentUser!.email!);
  }
}

/// 토큰에 대한 정보는 currentUser가 가지고 있고
/// currentUser가 null이 아니라면 로그인 되어 있는 상태로 볼 수 있음
/// onAuthStateChange로 로그인 상태(로그아웃)에 대한 상태를 감지하여 로그인 되어있지 않다고 판단하고
/// 로그인 화면으로 보낼 수 있음
/// 전역 프로바이더로 만들어서 관리
/// 홈 화면에서 로그인 상태 확인 가능해야 함
