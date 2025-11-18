import 'package:flutter/material.dart';

class ConfirmExitDialog extends StatelessWidget {
  const ConfirmExitDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 290,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 42,
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              const Text(
                "코스 수정을 취소하시겠습니까?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context, true),
                child: _btn("확인", Colors.orange, Colors.white),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.pop(context, false),
                child: _btn("취소", const Color(0xFFF2F2F2), Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn(String text, Color bg, Color fg) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold),
      ),
    );
  }
}
