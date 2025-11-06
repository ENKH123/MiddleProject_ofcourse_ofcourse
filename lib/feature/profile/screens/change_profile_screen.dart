import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChangeProfileScreen extends StatelessWidget {
  ChangeProfileScreen({super.key});

  final TextEditingController nameCtrl = TextEditingController(text: '닉네임');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필 변경'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // 아바타
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade400,
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),

            const SizedBox(height: 20),

            // 이름 입력
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
                onPressed: () async {
                  // 프로필 변경 확인 팝업
                  // final ok = await showConfirmDialog(
                  //   context,
                  //   title: 'Do you really want to change?',
                  //   message: 'Your profile information will be updated.',
                  //   cancelText: 'Cancel',
                  //   confirmText: 'Change',
                  //   destructive: false,
                  // );
                  // if (ok == true) {
                  //   // 저장 로직… (예: Supabase 업데이트)
                  //   Navigator.pop(context); // 성공 후 뒤로
                  // }
                  // Supabase 업데이트 로직 연결 시 여기서 처리

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('프로필이 변경되었어요!')));

                  // 뒤로 돌아가기 (스택이 있으면 pop, 없으면 /profile로 이동)
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/profile');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002E6E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
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
