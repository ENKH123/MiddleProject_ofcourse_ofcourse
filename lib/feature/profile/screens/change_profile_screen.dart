import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:of_course/feature/profile/viewmodels/change_profile_viewmodel.dart';
import 'package:provider/provider.dart';

class ChangeProfileScreen extends StatelessWidget {
  const ChangeProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChangeProfileViewModel>();

    return WillPopScope(
      onWillPop: () async {
        return await _maybeShowDiscardDialog(context, vm);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('프로필 변경'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final canPop = await _maybeShowDiscardDialog(context, vm);
              if (canPop && context.mounted) {
                context.pop();
              }
            },
          ),
        ),
        body: FutureBuilder(
          future: (vm.user == null && !vm.isLoading) ? vm.loadUser() : null,
          builder: (context, snapshot) {
            if (vm.isLoading && vm.user == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildBody(context, vm);
          },
        ),
      ),
    );
  }

  Future<bool> _maybeShowDiscardDialog(
    BuildContext context,
    ChangeProfileViewModel vm,
  ) async {
    if (!vm.hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: const Text('변경사항이 저장되지 않습니다'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                vm.resetChanges();
                Navigator.of(context).pop(true);
              },
              child: const Text('나가기'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Widget _buildBody(BuildContext context, ChangeProfileViewModel vm) {
    final canSave = vm.canSave;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _showImageSheet(context, vm),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xff003366),
                  backgroundImage: _imageProvider(vm),
                  child: _imageProvider(vm) == null
                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
                ),
                Positioned(bottom: 0, right: 0, child: _editIcon(context, vm)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 닉네임 입력 필드
          _nicknameField(vm),

          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '1~10자 가능',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 40),

          // 변경 버튼
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: canSave
                  ? () async {
                      FocusScope.of(context).unfocus(); // 키보드 내리기
                      final ok = await vm.save();
                      if (!context.mounted) return;

                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('프로필이 변경되었어요.')),
                        );
                        context.pop(true);
                      } else {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('저장 실패')));
                      }
                    }
                  : null,
              child: vm.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('변경'),
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider? _imageProvider(ChangeProfileViewModel vm) {
    if (vm.newImageFile != null) {
      return FileImage(vm.newImageFile!);
    }
    if (vm.profileImageUrl != null && vm.profileImageUrl!.isNotEmpty) {
      return NetworkImage(vm.profileImageUrl!);
    }
    return null;
  }

  Widget _editIcon(BuildContext context, ChangeProfileViewModel vm) {
    return GestureDetector(
      onTap: () => _showImageSheet(context, vm),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              offset: const Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: const Icon(Icons.edit, size: 18, color: Color(0xff003366)),
      ),
    );
  }

  Widget _nicknameField(ChangeProfileViewModel vm) {
    final currentLength = vm.nicknameLength;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: vm.nicknameController,
        onChanged: vm.setNickname,
        textAlign: TextAlign.center,
        maxLines: 1,
        maxLength: 10,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        style: const TextStyle(color: Color(0xff030303)),
        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: '닉네임을 입력하세요',
          counter: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$currentLength/10',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  void _showImageSheet(BuildContext context, ChangeProfileViewModel vm) {
    final hasImage = vm.newImageFile != null || (vm.profileImageUrl != null);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('앨범에서 선택'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(vm, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('사진 촬영'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(vm, ImageSource.camera);
                },
              ),
              if (hasImage)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('이미지 삭제'),
                  onTap: () {
                    Navigator.pop(context);
                    vm.deleteImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ChangeProfileViewModel vm, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (picked != null) {
      vm.pickNewImage(File(picked.path));
    }
  }
}
