import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/feature/auth/viewmodels/register_viewmodel.dart';
import 'package:provider/provider.dart';

import '../../../core/components/loading_dialog.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RegisterViewModel(context),
      child: _RegisterScreen(),
    );
  }
}

class _RegisterScreen extends StatelessWidget {
  const _RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Consumer<RegisterViewModel>(
          builder: (context, viewmodel, child) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 40), //상단 여백
                          Text(
                            "프로필 정보 입력",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ProfileImage(viewmodel: viewmodel),
                          NicknameTextField(viewModel: viewmodel),
                        ],
                      ),
                    ),
                  ),
                  CompleteButton(),
                ],
              ),
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
void _showRegisterCompletePopup(
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
                      style: ElevatedButton.styleFrom(),
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (isSuccess) {
                          viewmodelR.uploadProfileImage();
                          context.go('/home');
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
  final RegisterViewModel viewmodel;
  const ProfileImage({super.key, required this.viewmodel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        viewmodel.pickImage(context);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(60),
        child: SizedBox(
          width: 120,
          height: 120,
          child: viewmodel.image != null
              ? Image.file(File(viewmodel.image!.path), fit: BoxFit.cover)
              : Stack(
                  children: [
                    Icon(
                      Icons.account_circle_sharp,
                      size: 120,
                      color: Color(0xff003366),
                      fill: 1.0,
                    ), // 이미지가 없으면 아이콘
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ), //가져온 이미지,
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
        return SizedBox(
          width: double.maxFinite,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(),
            onPressed: viewmodel.isNicknameValid
                ? () async {
                    showFullScreenLoading(context);
                    final RegisterResult rgResult = await viewmodel.isSucceed();
                    Navigator.of(context).pop();
                    _showRegisterCompletePopup(
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
  final RegisterViewModel viewModel;
  const NicknameTextField({super.key, required this.viewModel});

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
            controller: viewModel.controller,
            onChanged: viewModel.updatedNickname,
            maxLines: 1,
            maxLength: 10,

            decoration: InputDecoration(
              labelText: '2 ~ 10자 사이로 입력해주세요',
              labelStyle: viewModel.isNicknameValid
                  ? null
                  : TextStyle(color: Colors.redAccent),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
                // 텍스트 필드 테두리
                borderSide: viewModel.isNicknameValid
                    ? BorderSide(width: 1)
                    : BorderSide(width: 1, color: Colors.redAccent),
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
