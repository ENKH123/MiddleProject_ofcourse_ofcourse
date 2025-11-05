import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  GoogleSignInAccount? _user;
  @override
  void initState() {
    _initializeGoogleSignIn();
    super.initState();
  }

  Future<void> _initializeGoogleSignIn() async {
    final scopes = ['email', 'profile'];
    final googleSignIn = GoogleSignIn.instance;
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '263065720661-k84n73rspv3unh1v4o9s7i38epccj93p.apps.googleusercontent.com',
      clientId:
          '263065720661-jc08s65ja8u56o77hrv9samvc8srjg7m.apps.googleusercontent.com',
    );
    final googleUser = await googleSignIn.attemptLightweightAuthentication();
    if (googleUser == null) {
      throw AuthException('Failed to sign in with Google.');
    }

    final authorization =
        await googleUser.authorizationClient.authorizationForScopes(scopes) ??
        await googleUser.authorizationClient.authorizeScopes(scopes);
    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw AuthException('No ID Token found.');
    }
    await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: authorization.accessToken,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFAFAFA),
      body: SafeArea(
        child: Stack(
          children: [
            // 로그인 버튼
            GoogleLoginButton(clickEvent: _initializeGoogleSignIn),
            // 앱 로고
            AppLogo(),
          ],
        ),
      ),
    );
  }
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: SizedBox(
            width: double.maxFinite,
            height: double.maxFinite,
            child: Center(
              child: Image.asset('assets/appLogo.png', width: 260, height: 260),
            ),
          ),
        ),
        Expanded(flex: 1, child: SizedBox()),
      ],
    );
  }
}

class GoogleLoginButton extends StatelessWidget {
  final Future<void> Function() clickEvent;
  const GoogleLoginButton({super.key, required this.clickEvent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      height: double.maxFinite,
      child: Center(
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            fixedSize: Size(280, 48),
          ),
          onPressed: () async {
            await clickEvent();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 16,
            children: [
              Image.asset('assets/googleLogo.png', width: 20, height: 20),
              const Text("Sign in with another provider"),
            ],
          ),
        ),
      ),
    );
  }
}
