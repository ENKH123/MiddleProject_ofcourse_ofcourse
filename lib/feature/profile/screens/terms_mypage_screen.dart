import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
                  _buildTermsItem(
                    context,
                    '서비스 이용약관(필수)',
                    'https://www.notion.so/2a373873401a806bbd50c722ce583383?source=copy_link',
                  ),
                  _buildTermsItem(
                    context,
                    '개인정보 처리 방침(필수)',
                    'https://www.notion.so/2a373873401a80d4af70c36bfa4ce66a?source=copy_link',
                  ),
                  _buildTermsItem(
                    context,
                    '위치 기반 서비스 이용약관(필수)',
                    'https://www.notion.so/2a373873401a80b580eeefcb509a369b?source=copy_link',
                  ),
                  _buildTermsItem(
                    context,
                    '커뮤니티 운영정책(필수)',
                    'https://www.notion.so/2a373873401a80b1aefdde811dfc7ecf?source=copy_link',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 약관 항목 빌드
  Widget _buildTermsItem(BuildContext context, String title, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('링크를 열 수 없습니다')),
                  );
                }
              }
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

