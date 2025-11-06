import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/viewmodels/login_viewmodel.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFAFAFA),
      body: SafeArea(
        child: Consumer<LoginViewModel>(
          builder: (context, viewmodel, child) {
            void navigateOnSignIn() {
              if (viewmodel.userAccount != null) {
                // 로그인 성공 후 userAccount가 있으면 '/home'으로 이동
                context.go('/home'); // context.go를 사용하여 이전 스택을 지웁니다.
              } else {
                // userAccount가 없으면 (예: 신규 사용자) '/register'로 이동
                context.push('/register');
              }
            }

            return Stack(
              children: [
                // 로그인 버튼
                GoogleLoginButton(
                  clickEvent: viewmodel.googleSignIn,
                  onSignInSuccess: navigateOnSignIn,
                ),
                // 앱 로고
                AppLogo(),
                TextButton(
                  onPressed: () {
                    viewmodel.signOut;
                  },
                  child: Text("로그아웃"),
                ),
              ],
            );
          },
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
  final void Function() onSignInSuccess;
  const GoogleLoginButton({
    super.key,
    required this.clickEvent,
    required this.onSignInSuccess, // 새로운 필드
  });

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
            onSignInSuccess();
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
