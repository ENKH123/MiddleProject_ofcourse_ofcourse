import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지'), centerTitle: true),
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
              '닉네임',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // 프로필 수정 → /change_profile
            _menuButton(
              context,
              label: '프로필 수정',
              onTap: () => context.push('/change_profile'),
            ),

            _menuButton(
              context,
              label: '내가 만든 코스',
              onTap: () => context.push('/mypost'),
            ),
            _menuButton(
              context,
              label: '테마 선택',
              onTap: () {
                /* 팝업 연결 예정이면 여기서 호출 */
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
                onPressed: () {
                  // 로그아웃 처리 연결 예정이면 여기에
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Log Out tapped')),
                  );
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
              onPressed: () {
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
