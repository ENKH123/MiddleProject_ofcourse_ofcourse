import 'package:flutter/material.dart';
import 'package:of_course/feature/auth/viewmodels/onboarding_viewmodel.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingViewModel(),
      child: _OnboardingScreen(),
    );
  }
}

class _OnboardingScreen extends StatelessWidget {
  const _OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingViewModel>(
      builder: (context, viewmodel, child) {
        return Stack(
          children: [
            PageView.builder(
              controller: viewmodel.pageController,
              itemCount: viewmodel.maxPage,
              onPageChanged: (int newPage) {
                viewmodel.updatePage(newPage);
              },
              // 페이지 목록
              itemBuilder: (BuildContext context, int index) {
                return SizedBox.expand(
                  child: OnboardingBox(viewmodel: viewmodel),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox.expand(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        "SKIP",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.grey,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.maxFinite,
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text("시작하기"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class OnboardingBox extends StatelessWidget {
  final OnboardingViewModel viewmodel;
  const OnboardingBox({super.key, required this.viewmodel});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          'Page index : ${viewmodel.currentPage + 1}',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
