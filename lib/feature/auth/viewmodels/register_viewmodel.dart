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
  String _pickedImgPath = "";
  String get pickedImgPath => _pickedImgPath;

  XFile? _image;
  XFile? get image => _image;

  // 회원가입(계정생성)
  Future<void> registerSuccess([String? filePath]) async {
    if (filePath != null) {
      String userProfileImage = supabase.storage
          .from('profile')
          .getPublicUrl(filePath);
      SupabaseManager.shared.createUserProfile(
        _loginViewModel.googleUser?.email ?? "",
        _controller.text,
        userProfileImage,
      );
    } else {
      SupabaseManager.shared.createUserProfile(
        _loginViewModel.googleUser?.email ?? "",
        _controller.text,
      );
    }
  }

  // 프로필 이미지 선택
  Future<void> pickProfileImage(BuildContext context) async {
    _image = await _picker.pickImage(source: ImageSource.gallery);
    if (_image != null) {
      _pickedImgPath = _image!.path;
    }
    notifyListeners();
  }

  // 프로필 이미지 Bucket 업로드
  Future<void> uploadProfileImage() async {
    if (_pickedImgPath.isNotEmpty) {
      final profileFile = File(_pickedImgPath);
      final profileFullPath =
          'public/${_loginViewModel.googleUser?.email}/${_image!.name}';
      await supabase.storage
          .from('profile')
          .upload(
            profileFullPath,
            profileFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      await registerSuccess(profileFullPath);
      notifyListeners();
    } else {
      await registerSuccess();
      notifyListeners();
    }
  }

  // 닉네임 2글자 이상 체크
  void updatedNickname(String value) {
    _isNicknameValid = value.length >= 2;
    notifyListeners();
  }

  // 닉네임 중복 체크
  Future<RegisterResult> isSucceed() async {
    // 닉네임 중복 여부
    bool nicknameSucceed = await SupabaseManager.shared.isDuplicatedNickname(
      _controller.text,
    );
    if (nicknameSucceed) {
      return RegisterResult.success;
    }
    return RegisterResult.duplicate;
  }
}
