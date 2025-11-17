import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/core/app_theme.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/feature/auth/viewmodels/login_viewmodel.dart';
import 'package:of_course/feature/profile/screens/terms_mypage_screen.dart';
import 'package:of_course/feature/profile/viewmodels/profile_viewmodel.dart';
import 'package:provider/provider.dart';

import '../../../core/components/custom_app_bar.dart';
import '../../../core/components/loading_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    LoginViewModel viewModel = context.watch<LoginViewModel>();

    return Scaffold(
      appBar: const CustomAppBar(title: '마이페이지', showBackButton: false),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: FutureBuilder(
          future: (vm.user == null && !vm.isLoading) ? vm.loadUser() : null,
          builder: (context, snapshot) {
            final user = vm.user;

            if (vm.isLoading && user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final imageUrl = vm.getProfileImageUrl();
            final nickname = user?.nickname ?? '닉네임 없음';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // 프로필 이미지 + 닉네임
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xff003366),
                        backgroundImage:
                            (imageUrl != null && imageUrl.isNotEmpty)
                            ? NetworkImage(imageUrl)
                            : null,
                        child: (imageUrl == null || imageUrl.isEmpty)
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 60,
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        nickname,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ✅ 버튼들 – padding / 폭 확실히
                _menuButton(
                  context,
                  label: '프로필 수정',
                  onTap: () async {
                    final changed = await context.push<bool>('/change_profile');
                    if (changed == true) {
                      vm.loadUser(); // 변경 후 다시 로딩
                    }
                  },
                ),
                _menuButton(
                  context,
                  label: '내가 만든 코스',
                  onTap: () async {
                    final userId = await SupabaseManager.shared
                        .getMyUserRowId();
                    if (userId == null) return;
                    context.push('/mypost', extra: userId);
                  },
                ),
                _menuButton(
                  context,
                  label: '테마 선택',
                  onTap: () async {
                    final picked = await showThemeModeDialog(
                      context,
                      current: themeModeNotifier.value,
                    );
                    if (picked != null) {
                      themeModeNotifier.value = picked;
                    }
                  },
                ),
                _menuButton(
                  context,
                  label: '약관 확인',
                  onTap: () => showDialog(
                    context: context,
                    barrierColor: Colors.black54,
                    barrierDismissible: true,
                    builder: (context) => const TermsOfUseScreen(),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      viewModel.isDialogType(DialogType.logOut);
                      _showSignOutPopup(context, viewModel);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('로그아웃'),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      viewModel.isDialogType(DialogType.reSign);
                      _showSignOutPopup(context, viewModel);
                    },
                    child: const Text(
                      '회원탈퇴',
                      style: TextStyle(
                        color: Colors.red,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _menuButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6), // ✅ 위/아래 padding 명확히
      child: SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

void _showSignOutPopup(BuildContext context, LoginViewModel viewModel) {
  showDialog(
    context: context,

    // 다이얼로그 외부를 탭해도 닫히지 않게 설정 (배경 클릭 방지)
    // barrierDismissible: false,
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
                spacing: 20,
                children: [
                  viewModel.dialogType == DialogType.logOut
                      ? Text("로그아웃 하시겠습니까?", style: TextStyle(fontSize: 20))
                      : Text("정말 탈퇴하시겠습니까?", style: TextStyle(fontSize: 20)),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (viewModel.dialogType == DialogType.logOut) {
                              try {
                                showFullScreenLoading(context);
                                await context.read<LoginViewModel>().signOut(
                                  context,
                                );
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                                context.go('/login');
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('로그아웃 실패: $e')),
                                );
                              }
                            } else {
                              // 회원탈퇴 후 로그아웃
                              showFullScreenLoading(context);
                              await context.read<LoginViewModel>().resign();
                              await context.read<LoginViewModel>().signOut(
                                context,
                              );
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                              context.go('/login');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('회원탈퇴가 완료되었습니다.')),
                              );
                            }
                          },
                          child: const Text("확인"),
                        ),
                      ),
                      SizedBox.fromSize(size: Size(8, 0)),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                          child: const Text(
                            "취소",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ],
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
