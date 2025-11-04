import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 로그인 버튼
            GoogleLoginButton(),
            Column(
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    width: double.maxFinite,
                    height: double.maxFinite,
                    child: Center(
                      child: Image.asset(
                        'assets/appLogo.png',
                        width: 260,
                        height: 260,
                      ),
                    ),
                  ),
                ),
                Expanded(flex: 1, child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GoogleLoginButton extends StatelessWidget {
  const GoogleLoginButton({super.key});

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
          onPressed: () {},
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
