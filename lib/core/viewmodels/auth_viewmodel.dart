import 'package:flutter/cupertino.dart';
import 'package:gotrue/src/types/user.dart';
import 'package:of_course/main.dart';

class AuthViewModel extends ChangeNotifier {
  User? _user;
  User? get user => _user;

  AuthViewModel() {
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    _user = supabase.auth.currentUser;
  }

  // bool isLoggedIn() {
  //   return _user != null ? true : false;
  // }
}

/// 토큰에 대한 정보는 currentUser가 가지고 있고
/// currentUser가 null이 아니라면 로그인 되어 있는 상태로 볼 수 있음
/// onAuthStateChange로 로그인 상태(로그아웃)에 대한 상태를 감지하여 로그인 되어있지 않다고 판단하고
/// 로그인 화면으로 보낼 수 있음
/// 전역 프로바이더로 만들어서 관리
/// 홈 화면에서 로그인 상태 확인 가능해야 함
