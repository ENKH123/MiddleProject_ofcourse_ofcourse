import 'package:flutter/material.dart';
import 'package:of_course/feature/auth/viewmodels/login_viewmodel.dart';
import 'package:of_course/feature/onboarding/viewmodels/onboarding_viewmodel.dart';
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
    final viewmodelL = context.read<LoginViewModel>();
    return Consumer<OnboardingViewModel>(
      builder: (context, viewmodel, child) {
        return Stack(
          children: [
            PageView.builder(
              controller: viewmodel.pageController,
              itemCount: viewmodel.totalPages,
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
                      onTap: () {
                        viewmodelL.finishOnboarding();
                      },
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
                    Column(
                      spacing: 12,
                      children: [
                        DotsIndicator(
                          currentPage: viewmodel.currentPage,
                          totalPages: viewmodel.totalPages,
                        ),
                        SizedBox(
                          width: double.maxFinite,
                          child: ElevatedButton(
                            onPressed:
                                viewmodel.currentPage < viewmodel.totalPages - 1
                                ? () {
                                    viewmodel.goToNextPage();
                                  }
                                : () {
                                    viewmodelL.finishOnboarding();
                                  },
                            child: viewmodel.currentPage >= 3
                                ? const Text("시작하기")
                                : const Text("다음"),
                          ),
                        ),
                      ],
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

// 인디케이터
class DotsIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const DotsIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) => _buildDot(index, context)),
    );
  }

  Widget _buildDot(int index, BuildContext context) {
    bool isActive = index == currentPage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: isActive ? 10.0 : 8.0,
      width: isActive ? 10.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? Color(0xFF003366) : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(5.0),
      ),
    );
  }
}

// 온보딩 화면
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
