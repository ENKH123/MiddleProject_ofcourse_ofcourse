import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFAFAFA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  SizedBox(height: 40),
                  Text(
                    "프로필 정보 입력",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  ProfileImage(),
                  NicknameTextField(),
                ],
              ),
              CompleteButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileImage extends StatelessWidget {
  const ProfileImage({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('Box가 클릭되었습니다!');
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Icon(
          Icons.account_circle_sharp,
          size: 120,
          color: Color(0xff003366),
          fill: 1.0,
        ),
      ),
    );
  }
}

class CompleteButton extends StatelessWidget {
  const CompleteButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Color(0xff003366)),
        onPressed: () {
          print("입력 완료 버튼 눌림");
        },
        child: Text("입력 완료", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class NicknameTextField extends StatelessWidget {
  const NicknameTextField({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(
            "닉네임",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter your nickname',
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
                // 텍스트 필드 테두리
                // borderSide: BorderSide(
                //   width: 1,
                //   color: Colors.redAccent,
                // ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
