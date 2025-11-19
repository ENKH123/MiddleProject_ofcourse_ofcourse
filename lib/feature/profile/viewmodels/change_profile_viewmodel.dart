import 'dart:io';

import 'package:flutter/material.dart';
import 'package:of_course/core/data/core_data_source.dart';
import 'package:of_course/core/models/supabase_user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangeProfileViewModel extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  SupabaseUserModel? user;

  String nickname = '';
  String? profileImageUrl; // 화면에 보여줄 최종 URL
  String? oldStoragePath; // 이전에 쓰던 storage 경로 (삭제용)

  File? newImageFile; // 새로 선택한 이미지
  bool isDeleted = false;
  bool isLoading = false;
  bool isSaving = false;

  String _initialNickname = '';
  String? _initialProfileImageUrl;
  String? _initialOldStoragePath;

  void setNickname(String value) {
    // 띄어쓰기 제거
    final noSpace = value.replaceAll(' ', '');
    nickname = noSpace;
    notifyListeners();
  }

  bool get isNicknameTooLong => nickname.length > 10;
  bool get isNicknameEmpty => nickname.trim().isEmpty;

  // 버튼 활성화 여부
  bool get canSave => !isSaving && !isNicknameEmpty && !isNicknameTooLong;

  // 유저 정보 불러오기
  Future<void> loadUser() async {
    isLoading = true;
    notifyListeners();

    final email = supabase.auth.currentUser?.email;
    if (email != null) {
      user = await CoreDataSource.instance.fetchPublicUser(email);
    }

    nickname = user?.nickname ?? '';

    final raw = user?.profile_img;
    if (raw != null && raw.isNotEmpty) {
      if (raw.startsWith('http')) {
        // DB에 URL이 저장된 경우
        profileImageUrl = raw;

        final baseUrl = supabase.storage.from('profile').getPublicUrl('');
        if (raw.startsWith(baseUrl)) {
          oldStoragePath = raw.substring(baseUrl.length);
        }
      } else {
        // DB에 storage 경로만 저장된 경우
        oldStoragePath = raw;
        profileImageUrl = supabase.storage.from('profile').getPublicUrl(raw);
      }
    } else {
      profileImageUrl = null;
      oldStoragePath = null;
    }

    // 여기서 초기 상태 백업
    _initialNickname = nickname;
    _initialProfileImageUrl = profileImageUrl;
    _initialOldStoragePath = oldStoragePath;
    isDeleted = false;
    newImageFile = null;

    isLoading = false;
    notifyListeners();
  }

  void pickNewImage(File file) {
    newImageFile = file;
    isDeleted = false;
    notifyListeners();
  }

  void deleteImage() {
    newImageFile = null;
    profileImageUrl = null;
    isDeleted = true;
    notifyListeners();
  }

  // 변경사항 여부
  bool get hasChanges {
    final nicknameChanged = nickname != _initialNickname;
    final imageChanged =
        isDeleted ||
        newImageFile != null ||
        profileImageUrl != _initialProfileImageUrl;

    return nicknameChanged || imageChanged;
  }

  // 변경사항 되돌리기
  void resetChanges() {
    nickname = _initialNickname;
    profileImageUrl = _initialProfileImageUrl;
    oldStoragePath = _initialOldStoragePath;
    newImageFile = null;
    isDeleted = false;
    notifyListeners();
  }

  Future<bool> save() async {
    if (user == null) return false;

    isSaving = true;
    notifyListeners();

    String? newStoragePath;
    String? newPublicUrl;

    // 1) 새 이미지 업로드
    if (newImageFile != null) {
      final email = user!.email;
      final ext = newImageFile!.path.split('.').last;
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
      newStoragePath = '$email/$fileName';

      await supabase.storage
          .from('profile')
          .upload(newStoragePath, newImageFile!);

      newPublicUrl = supabase.storage
          .from('profile')
          .getPublicUrl(newStoragePath);
    }

    // 2) 이전 이미지 삭제 (새 이미지 선택 또는 삭제한 경우)
    if ((newImageFile != null || isDeleted) && oldStoragePath != null) {
      await supabase.storage.from('profile').remove([oldStoragePath!]);
    }

    // 3) DB 업데이트
    final updateData = <String, dynamic>{'nickname': nickname.trim()};

    if (isDeleted && newPublicUrl == null) {
      updateData['profile_img'] = null;
    } else if (newPublicUrl != null) {
      updateData['profile_img'] = newPublicUrl; // 앞으로는 항상 URL로 저장
    }

    await supabase.from('users').update(updateData).eq('id', user!.id);

    final currentProfileUrl = isDeleted
        ? null
        : (newPublicUrl ?? profileImageUrl);

    profileImageUrl = currentProfileUrl;

    // storage path 갱신
    if (newStoragePath != null) {
      oldStoragePath = newStoragePath;
    } else if (isDeleted) {
      oldStoragePath = null;
    }
    // 새 기준으로 초기 상태 다시 세팅
    _initialNickname = nickname.trim();
    _initialProfileImageUrl = profileImageUrl;
    _initialOldStoragePath = oldStoragePath;
    isDeleted = false;
    newImageFile = null;

    isSaving = false;
    notifyListeners();
    return true;
  }
}
