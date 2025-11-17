import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/supabase_user_model.dart';
import 'package:of_course/core/providers/alert_provider.dart';
import 'package:of_course/main.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum DialogType { logOut, reSign }

class LoginViewModel extends ChangeNotifier {
  //TODO: 호출
  //TODO: 결과

  GoogleSignInAccount? _googleUser;
  GoogleSignInAccount? get googleUser => _googleUser;

  SupabaseUserModel? userAccount;

  late DialogType _dialogType;
  DialogType get dialogType => _dialogType;

  void isDialogType(DialogType type) {
    _dialogType = type;
    notifyListeners();
  }

  // 로그인
  Future<void> googleSignIn(BuildContext context) async {
    final scopes = ['email', 'profile'];

    // 구글 프로바이더 작동
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize(
      serverClientId:
          '263065720661-k84n73rspv3unh1v4o9s7i38epccj93p.apps.googleusercontent.com',
      clientId:
          '263065720661-jc08s65ja8u56o77hrv9samvc8srjg7m.apps.googleusercontent.com',
    );
    // 구글 프로바이더 작동

    // 구글에서 유저 정보 _googleUser로 전달
    _googleUser = await googleSignIn.authenticate();
    // 구글에서 유저 정보 _googleUser로 전달

    // 구글 계정 없음
    if (_googleUser == null) {
      throw AuthException('Failed to sign in with Google.');
    }
    // 구글 계정 없음

    // 토큰 발급 과정?
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
    // 토큰 발급 과정?

    // supabase public 테이블에 _googleUser로 받은 이메일이 있는지 확인
    userAccount = await SupabaseManager.shared.fetchPublicUser(
      _googleUser!.email,
    );
    // supabase public 테이블에 _googleUser로 받은 이메일이 있는지 확인

    // 리얼타임 채널 재구독
    final alertViewModel = context.read<AlertProvider>();
    alertViewModel.resubscribeRealtime();
    // 리얼타임 채널 재구독

    SupabaseManager.shared.fetchAlerts();
  }

  // 로그아웃
  Future<void> signOut(BuildContext context) async {
    final alertViewModel = context.read<AlertProvider>();
    alertViewModel.unsubscribeRealtime();
    await GoogleSignIn.instance.signOut();
    await supabase.auth.signOut(scope: SignOutScope.global);
  }

  // 회원탈퇴
  Future<void> resign() async {
    await SupabaseManager.shared.resign();
  }

  // // 로그인
  // Future<void> googleSignIn(BuildContext context) async {
  //   GoogleAuthManager.shared.googleSignIn(context);
  //   notifyListeners();
  // }
  //
  // // 로그아웃
  // Future<void> signOut(BuildContext context) async {
  //   GoogleAuthManager.shared.signOut(context);
  //   notifyListeners();
  // }
  //
  // // 회원탈퇴
  // Future<void> resign() async {
  //   await SupabaseManager.shared.resign();
  //   notifyListeners();
  // }
}
