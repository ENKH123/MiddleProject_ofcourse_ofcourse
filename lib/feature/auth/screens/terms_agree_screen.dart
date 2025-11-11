import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../viewmodels/terms_viewmodel.dart';

class TermsAgreeScreen extends StatelessWidget {
  const TermsAgreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TermsViewModel(),
      child: _TermsAgreeScreen(),
    );
  }
}

class _TermsAgreeScreen extends StatelessWidget {
  const _TermsAgreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFAFAFA),
      appBar: AppBar(
        backgroundColor: Color(0xffFAFAFA),
        title: const Text(
          "약관 동의",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Consumer<TermsViewModel>(
          builder: (context, viewmodel, child) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    spacing: 12,
                    children: [
                      TermBox(
                        termsName: '서비스 이용약관 (필수)',
                        term: viewmodel.term01,
                        onClick: () => viewmodel.termClick(1),
                        termsLink:
                            'https://mammoth-sassafras-ff5.notion.site/2a373873401a806bbd50c722ce583383?source=copy_link',
                      ),
                      TermBox(
                        termsName: '개인정보 처리 방침 (필수)',
                        term: viewmodel.term02,
                        onClick: () => viewmodel.termClick(2),
                        termsLink:
                            'https://mammoth-sassafras-ff5.notion.site/2a373873401a80d4af70c36bfa4ce66a?source=copy_link',
                      ),
                      TermBox(
                        termsName: '위치 기반 서비스 이용약관 (필수)',
                        term: viewmodel.term03,
                        onClick: () => viewmodel.termClick(3),
                        termsLink:
                            'https://mammoth-sassafras-ff5.notion.site/2a373873401a80b580eeefcb509a369b?source=copy_link',
                      ),
                      TermBox(
                        termsName: '커뮤니티 운영정책 (필수)',
                        term: viewmodel.term04,
                        onClick: () => viewmodel.termClick(4),
                        termsLink:
                            'https://mammoth-sassafras-ff5.notion.site/2a373873401a80b1aefdde811dfc7ecf?source=copy_link',
                      ),
                    ],
                  ),
                  NextButton(
                    allCheck: viewmodel.allTermsAgreed
                        ? () {
                            context.push('/register');
                          }
                        : null,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class TermBox extends StatelessWidget {
  final String termsName;
  final bool term;
  final String termsLink;
  final VoidCallback onClick;
  const TermBox({
    super.key,
    required this.termsLink,
    required this.termsName,
    required this.term,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onClick,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    term ? Icons.check_circle : Icons.circle_outlined,
                    color: Color(0xff003366),
                    size: 28,
                  ),
                ),
              ),

              Text(
                termsName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          GestureDetector(
            onTap: () async {
              print("전체보기 눌림");
              final uri = Uri.parse(termsLink);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            // 버튼 영역 확장을 위해 SizedBox 사용
            child: SizedBox(
              height: double.maxFinite,
              width: 80,
              child: Center(
                child: Text(
                  "전체보기",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.blue,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NextButton extends StatelessWidget {
  final VoidCallback? allCheck;
  const NextButton({super.key, required this.allCheck});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Color(0xff003366)),
        onPressed: allCheck,
        child: Text("다음", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
