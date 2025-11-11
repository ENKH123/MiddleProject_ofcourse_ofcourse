import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/core/app_theme.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/feature/auth/viewmodels/login_viewmodel.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {
              context.push('/alert');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xff003366),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 60),
            ),
            const SizedBox(height: 12),
            const Text(
              '닉네임', //데이터 가져올 예정
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            _menuButton(
              context,
              label: '프로필 수정',
              onTap: () => context.push('/change_profile'),
            ),
            _menuButton(
              context,
              label: '내가 만든 코스',
              onTap: () async {
                final userId = await SupabaseManager.shared.getMyUserRowId();
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
              label: '약관확인',
              onTap: () => context.push('/check_thrms'),
            ),

            const SizedBox(height: 4),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await context.read<LoginViewModel>().signOut();
                    context.go('/login');
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('로그아웃 실패: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Log Out'),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                await context.read<LoginViewModel>().resign();
                context.go('/login');
                // 회원탈퇴 팝업/라우팅 연결 예정
              },
              child: const Text(
                'Cancel Membership',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
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
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
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
