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
      setState(() => _profileImage = File(picked.path));
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

  Future<void> _saveProfile() async {
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

      // 이미지 업로드
      if (_profileImage != null) {
        avatarUrl = await _uploadAvatar(_profileImage!, user.id);
      }

      // users 테이블 업데이트
      final updates = <String, dynamic>{
        _nicknameColumn: nameCtrl.text.trim(),
        if (avatarUrl != null) _profileColumn: avatarUrl,
      };

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
                        onTap: _pickImage,
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
            SizedBox(
              width: 260,
              child: TextField(
                controller: nameCtrl,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '닉네임을 입력하세요',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
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
                  backgroundColor: const Color(0xFF002E6E),
                  foregroundColor: Colors.white,
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
