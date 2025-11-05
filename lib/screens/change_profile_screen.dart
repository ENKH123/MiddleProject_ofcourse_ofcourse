// lib/screens/change_profile_screen.dart
import 'package:flutter/material.dart';

import '../widgets/confirm_dialog.dart';

class ChangeProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile Change'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 40),
            CircleAvatar(radius: 60, backgroundColor: Colors.grey[400]),
            SizedBox(height: 20),
            SizedBox(
              width: 260,
              child: TextField(
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'JohnDoe',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            SizedBox(
              width: 260,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  // 프로필 변경 확인 팝업
                  final ok = await showConfirmDialog(
                    context,
                    title: 'Do you really want to change?',
                    message: 'Your profile information will be updated.',
                    cancelText: 'Cancel',
                    confirmText: 'Change',
                    destructive: false,
                  );
                  if (ok == true) {
                    // 저장 로직… (예: Supabase 업데이트)
                    Navigator.pop(context); // 성공 후 뒤로
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF002E6E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Change',
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
