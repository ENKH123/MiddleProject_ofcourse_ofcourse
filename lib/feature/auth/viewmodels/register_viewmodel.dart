import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/feature/auth/viewmodels/login_viewmodel.dart';
import 'package:provider/provider.dart';

enum RegisterResult { success, duplicate }

class RegisterViewModel extends ChangeNotifier {
  // 로그인 뷰모델 주입
  LoginViewModel _loginViewModel;

  RegisterViewModel(BuildContext context)
    : _loginViewModel = context.read<LoginViewModel>();

  // 텍스트필드 컨트롤러
  final TextEditingController _controller = TextEditingController();
  TextEditingController get controller => _controller;

  String editorText = "";

  // 닉네임 2글자 이상
  bool _isNicknameValid = false;
  bool get isNicknameValid => _isNicknameValid;

  // 이미지 피커
  ImagePicker _picker = ImagePicker();
  ImagePicker get picker => _picker;

  //TODO: Provider에서 context로 LoginViewModel의 email 가져오기
  Future<void> registerSuccess() async {
    SupabaseManager.shared.createUserProfile(
      _loginViewModel.googleUser?.email ?? "",
      _controller.text,
    );
  }

  // Future<void> _handleImageUpload() async {
  //   try {
  //     final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
  //
  //   } catch (e) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('이미지를 선택하는 중 오류가 발생했습니다: $e')));
  //   }
  // }

  void updatedNickname(String value) {
    _isNicknameValid = value.length >= 2;
    notifyListeners();
  }

  Future<RegisterResult> isDuplicatedNickname() async {
    if (await SupabaseManager.shared.isDuplicatedNickname(_controller.text)) {
      await Future.delayed(const Duration(milliseconds: 1000));
      return RegisterResult.success;
    }
    await Future.delayed(const Duration(milliseconds: 1000));
    return RegisterResult.duplicate;
  }
}
