import 'package:flutter/material.dart';

/// 약관 확인 팝업 화면
class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Expanded(
                    child: Text(
                      '약관',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // 뒤로가기 버튼과 균형 맞추기
                ],
              ),
            ),
            // 약관 목록
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTermsItem(context, '약관 1'),
                  _buildTermsItem(context, '약관 2'),
                  _buildTermsItem(context, '약관 3'),
                  _buildTermsItem(context, '약관 4'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 약관 항목 빌드
  Widget _buildTermsItem(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: 외부 URL로 연결
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title 전체보기 - URL 연결 기능 추가 예정')),
              );
            },
            child: const Text(
              '전체보기',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

