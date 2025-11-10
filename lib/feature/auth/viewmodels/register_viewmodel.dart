import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/feature/auth/viewmodels/login_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../main.dart';

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

  // 선택된 프로필 사진
  XFile? _pickedImg;
  XFile? get pickedImg => _pickedImg;

  XFile? _image;
  XFile? get image => _image;

  //TODO: Provider에서 context로 LoginViewModel의 email 가져오기
  Future<void> registerSuccess() async {
    SupabaseManager.shared.createUserProfile(
      _loginViewModel.googleUser?.email ?? "",
      _controller.text,
    );
  }

  Future<void> pickProfileImage(BuildContext context) async {
    _image = await _picker.pickImage(source: ImageSource.gallery);
    if (_image != null) {
      _pickedImg = XFile(_image!.path);
    }
    notifyListeners();
  }

  Future<void> uploadProfileImage() async {
    final profileFile = File(_image!.path);
    final String fullPath = await supabase.storage
        .from('profile')
        .upload(
          'public/${_controller.text}/${_image!.name}',
          profileFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
  }

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
