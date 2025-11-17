import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangeProfileScreen extends StatefulWidget {
  const ChangeProfileScreen({super.key});

  @override
  State<ChangeProfileScreen> createState() => _ChangeProfileScreenState();
}

class _ChangeProfileScreenState extends State<ChangeProfileScreen> {
  final TextEditingController nameCtrl = TextEditingController(text: '닉네임');
  File? _profileImage;
  bool _isSaving = false;

  // 이미지 삭제 여부 플래그 추가
  bool _isImageDeleted = false;

  final supabase = Supabase.instance.client;

  // Supabase 설정
  static const _bucketName = 'profile';
  static const _tableName = 'users';
  static const _profileColumn = 'profile_img';
  static const _nicknameColumn = 'nickname';
  static const _emailColumn = 'email';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path); // 새 이미지를 선택하면 삭제 상태 해제
        _isImageDeleted = false;
      });
    }
  }

  Future<String> _uploadAvatar(File file, String userId) async {
    final filePath =
        '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await supabase.storage
        .from(_bucketName)
        .upload(
          filePath,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    return supabase.storage.from(_bucketName).getPublicUrl(filePath);
  }

  // ✅ 연필 버튼 눌렀을 때 바텀시트 띄우는 함수 추가
  Future<void> _onEditAvatarPressed() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('이미지 변경'),
                onTap: () => Navigator.pop(context, 'change'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('이미지 삭제'),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        );
      },
    );

    if (result == 'change') {
      await _pickImage();
    } else if (result == 'delete') {
      setState(() {
        _profileImage = null;
        _isImageDeleted = true; // ✅ 삭제 플래그 on
      });
    }
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요해요.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? avatarUrl;

      // ✅ 이미지 업로드 (있을 때만)
      if (_profileImage != null) {
        avatarUrl = await _uploadAvatar(_profileImage!, user.id);
      }

      // ✅ 업데이트할 데이터 구성
      final updates = <String, dynamic>{_nicknameColumn: nameCtrl.text.trim()};

      // ✅ 이미지 변경/삭제 상태에 따라 profile_img 처리
      if (avatarUrl != null) {
        // 새 이미지 업로드한 경우: 새 URL 저장
        updates[_profileColumn] = avatarUrl;
      } else if (_isImageDeleted) {
        // 이미지 삭제만 한 경우: profile_img를 null로 업데이트
        updates[_profileColumn] = null;
      }
      // 아무것도 안 건드린 경우: profile_img는 건드리지 않음

      await supabase
          .from(_tableName)
          .update(updates)
          .eq(_emailColumn, user.email!);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프로필이 성공적으로 변경되었습니다')));

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/profile');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필 변경'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // 사진 + 수정버튼
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Material(
                      elevation: 2,
                      color: const Color(0xFF002E6E),
                      shape: const CircleBorder(),
                      child: InkWell(
                        // ⬇️⬇️ 여기 onTap 수정됨
                        onTap: _onEditAvatarPressed,
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 닉네임 입력
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: Color(0xfffafafa),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: TextField(
                controller: nameCtrl,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xff030303)),
                decoration: InputDecoration(
                  hintText: '닉네임을 입력하세요',
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 변경 버튼
            SizedBox(
              width: 260,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        '변경',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
