import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/supabase_user_model.dart';
import 'package:of_course/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginViewModel extends ChangeNotifier {
  GoogleSignInAccount? _googleUser;
  GoogleSignInAccount? get googleUser => _googleUser;

  SupabaseUserModel? userAccount;

  Future<void> googleSignIn() async {
    // 구글 프로바이더 작동
    final scopes = ['email', 'profile'];
    final googleSignIn = GoogleSignIn.instance;
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '263065720661-k84n73rspv3unh1v4o9s7i38epccj93p.apps.googleusercontent.com',
      clientId:
          '263065720661-jc08s65ja8u56o77hrv9samvc8srjg7m.apps.googleusercontent.com',
    );
    // 구글 프로바이더 작동

    // 구글에서 유저 정보 _googleUser로 전달
    _googleUser = await googleSignIn.attemptLightweightAuthentication();
    // 구글에서 유저 정보 _googleUser로 전달

    print(_googleUser);
    // 구글 계정 없음
    if (_googleUser == null) {
      throw AuthException('Failed to sign in with Google.');
    }
    // 구글 계정 없음

    // 무슨 코드??
    final authorization =
        await _googleUser?.authorizationClient.authorizationForScopes(scopes) ??
        await _googleUser?.authorizationClient.authorizeScopes(scopes);
    final idToken = googleUser?.authentication.idToken;
    if (idToken == null) {
      throw AuthException('No ID Token found.');
    }
    await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: authorization?.accessToken,
    );
    // 무슨 코드??

    supabase.auth.currentUser;
    supabase.auth.onAuthStateChange;

    /// 토큰에 대한 정보는 currentUser가 가지고 있고
    /// currentUser가 null이 아니라면 로그인 되어 있는 상태로 볼 수 있음
    /// onAuthStateChange로 로그인 상태(로그아웃)에 대한 상태를 감지하여 로그인 되어있지 않다고 판단하고
    /// 로그인 화면으로 보낼 수 있음
    /// 전역 프로바이더로 만들어서 관리
    /// 홈 화면에서 로그인 상태 확인 가능해야 함

    // supabase public 테이블에 _googleUser로 받은 이메일이 있는지 확인
    userAccount = await SupabaseManager.shared.getPublicUser(
      _googleUser!.email,
    );
    // supabase public 테이블에 _googleUser로 받은 이메일이 있는지 확인
    notifyListeners();
  }

  Future<void> signOut() async {
    await supabase.auth.signOut(scope: SignOutScope.global);
    await GoogleSignIn.instance.signOut();
    notifyListeners();
  }
}
