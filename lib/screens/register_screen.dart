import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFAFAFA),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      SizedBox(height: 40), //상단 여백
                      Text(
                        "프로필 정보 입력",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ProfileImage(), //TODO: 이미지 피커 적용
                      NicknameTextField(), //TODO: 텍스트필드 컨트롤러
                    ],
                  ),
                  CompleteButton(
                    nickname: "닉네임",
                  ), //TODO: 텍스트필드 컨트롤러로 버튼 enable/disable, 텍스트 필드 글자 가져오기
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//TODO: 분기점 적용
/// 닉네임 중복시
/// 정상 생성시
void _showRegisterComplePopup(BuildContext context, String nickname) {
  showDialog(
    context: context,
    // 다이얼로그 외부를 탭해도 닫히지 않게 설정 (배경 클릭 방지)
    barrierDismissible: false,

    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent, // Dialog 배경 투명하게
        child: Center(
          child: Container(
            width: 240,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 12,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Color(0xff003366),
                    //TODO: 닉네임 중복시
                    // Icons.close,
                    // color: Colors.red,
                    size: 40,
                  ),
                  Column(
                    children: [
                      Text("계정 생성 완료"),
                      Text.rich(
                        TextSpan(
                          children: <TextSpan>[
                            TextSpan(text: "닉네임 : "),
                            TextSpan(
                              text: "\"$nickname\"",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  //TODO: 닉네임 중복시
                  // Text("이미 있는 닉네임 입니다."),
                  SizedBox(
                    width: double.maxFinite,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff003366),
                      ),
                      onPressed: () {
                        print("로그인 하러 가기 버튼 눌림");
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        "로그인 하러 가기",
                        //TODO: 닉네임 중복시
                        // "확인"
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class ProfileImage extends StatelessWidget {
  const ProfileImage({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('프로필 사진 눌림');
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
  final String nickname;
  const CompleteButton({super.key, required this.nickname});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      //TODO: 최소 글자 수 못 채우면 버튼 비활성화
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Color(0xff003366)),
        onPressed: () {
          print("입력 완료 버튼 눌림");
          _showRegisterComplePopup(context, nickname);
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
