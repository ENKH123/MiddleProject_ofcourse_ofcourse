import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:of_course/feature/auth/data/auth_data_source.dart';
import 'package:of_course/feature/auth/viewmodels/login_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../main.dart';

enum RegisterResult { success, duplicate }

enum ProfilePickResult { camera, album }

class RegisterViewModel extends ChangeNotifier {
  // 로그인 뷰모델 주입
  final LoginViewModel _loginViewModel;

  RegisterViewModel(BuildContext context)
    : _loginViewModel = context.read<LoginViewModel>();

  // 텍스트필드 컨트롤러
  final TextEditingController _controller = TextEditingController();
  TextEditingController get controller => _controller;

  String _nickname = "";
  String get nickname => _nickname;

  // 닉네임 2글자 이상
  bool _isNicknameFieldValid = true;
  bool get isNicknameFieldValid => _isNicknameFieldValid;

  bool _isNicknameButtonValid = false;
  bool get isNicknameButtonValid => _isNicknameButtonValid;

  final int _minNicknameLength = 2;
  int get minNicknameLength => _minNicknameLength;

  final int _maxNicknameLength = 10;
  int get maxNicknameLength => _maxNicknameLength;
  // 이미지 피커
  final ImagePicker _picker = ImagePicker();
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
      AuthDataSource.instance.createUserProfile(
        _loginViewModel.googleUser?.email ?? "",
        _nickname,
        userProfileImage,
      );
    } else {
      AuthDataSource.instance.createUserProfile(
        _loginViewModel.googleUser?.email ?? "",
        _nickname,
      );
    }
  }

  // 프로필 이미지 선택
  Future<void> _pickProfileImageAlbum(BuildContext context) async {
    _image = await _picker.pickImage(source: ImageSource.gallery);
    if (_image != null) {
      _pickedImgPath = _image!.path;
    }
    notifyListeners();
  }

  Future<void> _pickProfileImageCamera(BuildContext context) async {
    _image = await _picker.pickImage(source: ImageSource.camera);
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
    // 공백 제거
    final noSpace = value.replaceAll(' ', '');

    if (_controller.text != noSpace) {
      _controller.value = _controller.value.copyWith(
        text: noSpace,
        selection: TextSelection.collapsed(offset: noSpace.length),
        composing: TextRange.empty,
      );
    }

    _nickname = noSpace;

    // 글자 수 확인
    final isTrue =
        _nickname.length >= _minNicknameLength &&
        _nickname.length <= _maxNicknameLength;

    _isNicknameFieldValid = isTrue;
    _isNicknameButtonValid = isTrue;

    notifyListeners();
  }

  // 닉네임 중복 체크
  Future<RegisterResult> isSucceed() async {
    // 닉네임 중복 여부
    bool nicknameSucceed = await AuthDataSource.instance.isDuplicatedNickname(
      _nickname,
    );
    if (nicknameSucceed) {
      return RegisterResult.success;
    }
    return RegisterResult.duplicate;
  }

  Future<void> pickImage(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("앨범에서 선택"),
                onTap: () async {
                  Navigator.pop(context);
                  _pickProfileImageAlbum(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("사진 촬영"),
                onTap: () async {
                  Navigator.pop(context);
                  _pickProfileImageCamera(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
