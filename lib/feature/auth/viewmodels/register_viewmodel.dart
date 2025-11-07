import 'package:flutter/cupertino.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/feature/auth/viewmodels/login_viewmodel.dart';
import 'package:provider/provider.dart';

enum RegisterResult { success, duplicate }

class RegisterViewModel extends ChangeNotifier {
  LoginViewModel _loginViewModel;

  RegisterViewModel(BuildContext context)
    : _loginViewModel = context.read<LoginViewModel>();

  TextEditingController _controller = TextEditingController();
  TextEditingController get controller => _controller;
  String editorText = "";
  bool _isNicknameValid = false;
  bool get isNicknameValid => _isNicknameValid;

  //TODO: Provider에서 context로 LoginViewModel의 email 가져오기
  Future<void> registerSuccess() async {
    SupabaseManager.shared.createUserProfile(
      _loginViewModel.googleUser?.email ?? "",
      _controller.text,
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
