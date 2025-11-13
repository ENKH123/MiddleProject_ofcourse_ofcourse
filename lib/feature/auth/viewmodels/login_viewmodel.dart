import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/supabase_user_model.dart';
import 'package:of_course/feature/alert/viewmodels/alert_viewmodel.dart';
import 'package:of_course/main.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginViewModel extends ChangeNotifier {
  GoogleSignInAccount? _googleUser;
  GoogleSignInAccount? get googleUser => _googleUser;

  SupabaseUserModel? userAccount;

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

    print(_googleUser);
    // 구글 계정 없음
    if (_googleUser == null) {
      throw AuthException('Failed to sign in with Google.');
    }
    // 구글 계정 없음

    // 무슨 코드??
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
    // 무슨 코드??

    // supabase public 테이블에 _googleUser로 받은 이메일이 있는지 확인
    userAccount = await SupabaseManager.shared.getPublicUser(
      _googleUser!.email,
    );
    final alertViewModel = context.read<AlertViewModel>();
    alertViewModel.resubscribeRealtime();
    // supabase public 테이블에 _googleUser로 받은 이메일이 있는지 확인
    notifyListeners();
  }

  Future<void> signOut(BuildContext context) async {
    final alertViewModel = context.read<AlertViewModel>();
    alertViewModel.unsubscribeRealtime();
    await GoogleSignIn.instance.signOut();
    await supabase.auth.signOut(scope: SignOutScope.global);
    notifyListeners();
  }

  Future<void> resign() async {
    await SupabaseManager.shared.resign();
    notifyListeners();
  }
}

/// 호출
/// 결과
