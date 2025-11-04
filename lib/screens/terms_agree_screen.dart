import 'package:flutter/material.dart';

class TermsAgreeScreen extends StatelessWidget {
  const TermsAgreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: TermsAgreeAppBar()),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                spacing: 12,
                children: [
                  TermBox(),
                  TermBox(),
                  TermBox(),
                  TermBox(),
                  TermBox(),
                ],
              ),
              NextButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class TermBox extends StatelessWidget {
  const TermBox({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Color(0xff003366), size: 32),
              Text(
                "개인정보 ~~~ 약관",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
          Text(
            "전체보기",
            style: TextStyle(
              color: Colors.blue,
              fontSize: 16,
              decoration: TextDecoration.underline,
              decorationColor: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class NextButton extends StatelessWidget {
  const NextButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Color(0xff003366)),
        onPressed: () {
          print("다음 버튼 눌림");
        },
        child: Text("다음", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class TermsAgreeAppBar extends StatelessWidget {
  const TermsAgreeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () {},
              icon: Icon(Icons.arrow_back_ios_new),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: const Text(
              "약관 동의",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Expanded(child: SizedBox()),
      ],
    );
  }
}
