import 'package:flutter/material.dart';

class OnboardingViewModel with ChangeNotifier {
  final List<String> _onboardingImages = [
    'assets/onboarding1.png',
    'assets/onboarding2.png',
    'assets/onboarding3.png',
    'assets/onboarding4.png',
  ];
  List<String> get onboardingImages => _onboardingImages;

  final PageController pageController = PageController(initialPage: 0);

  int _currentPage = 0;
  int get currentPage => _currentPage;

  final int _totalPages = 4;
  int get totalPages => _totalPages;

  void updatePage(int newPage) {
    if (_currentPage != newPage) {
      _currentPage = newPage;
      notifyListeners();
    }
  }

  void goToNextPage() {
    if (_currentPage < totalPages - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
