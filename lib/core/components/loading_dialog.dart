import 'package:flutter/material.dart';

void showFullScreenLoading(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // 사용자가 다이얼로그 바깥을 탭하여 닫을 수 없도록 설정
    builder: (context) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 4,
          strokeCap: StrokeCap.round,
        ),
      );
    },
  );

  // 비동기 작업 후 다이얼로그 닫기
  // Navigator.of(context).pop(); 호출
}
