import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/feature/auth/viewmodels/register_viewmodel.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFAFAFA),
      appBar: AppBar(backgroundColor: Color(0xffFAFAFA)),
      body: SafeArea(
        child: Consumer<RegisterViewModel>(
          builder: (context, viewmodel, child) {
            return Stack(
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
                          NicknameTextField(
                            controller: viewmodel.controller,
                            onChanged: viewmodel.updatedNickname,
                          ),
                        ],
                      ),
                      CompleteButton(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

//TODO: 분기점 적용
/// 닉네임 중복시
/// 정상 생성시
void _showRegisterComplePopup(
  BuildContext context,
  String nickname,
  RegisterResult result,
  RegisterViewModel viewmodelR,
) {
  final isSuccess = result == RegisterResult.success;
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
                    isSuccess ? Icons.check_circle_outline : Icons.close,
                    color: isSuccess ? Color(0xff003366) : Colors.red,
                    size: 40,
                  ),
                  isSuccess
                      ? Column(
                          children: [
                            Text("계정 생성 완료"),
                            Text.rich(
                              TextSpan(
                                children: <TextSpan>[
                                  TextSpan(text: "닉네임 : "),
                                  TextSpan(
                                    text: "\"$nickname\"",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        )
                      : const Text(
                          "이미 존재하는 닉네임입니다.",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                  SizedBox(
                    width: double.maxFinite,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff003366),
                      ),
                      onPressed: () {
                        print("로그인 하러 가기 버튼 눌림");
                        Navigator.of(context).pop();
                        if (isSuccess) {
                          context.go('/home');
                          viewmodelR.registerSuccess();
                        }
                      },
                      child: Text(
                        isSuccess ? "로그인" : "다시 입력",
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
  const CompleteButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RegisterViewModel>(
      builder: (context, viewmodel, child) {
        final bool isEnabled = viewmodel.isNicknameValid;
        return SizedBox(
          width: double.maxFinite,
          //TODO: 최소 글자 수 못 채우면 버튼 비활성화
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xff003366)),
            onPressed: isEnabled
                ? () async {
                    print("입력 완료 버튼 눌림");
                    final RegisterResult rgResult = await viewmodel
                        .isDuplicatedNickname();
                    _showRegisterComplePopup(
                      context,
                      viewmodel.controller.text,
                      rgResult,
                      viewmodel,
                    );
                  }
                : null,
            child: Text("입력 완료", style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }
}

class NicknameTextField extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String)? onChanged;
  const NicknameTextField({
    super.key,
    required this.controller,
    this.onChanged,
  });

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
            controller: controller,
            onChanged: onChanged,
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
