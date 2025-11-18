import 'package:flutter/material.dart';

class OnboardingViewModel with ChangeNotifier {
  // PageController 초기화
  final PageController pageController = PageController(initialPage: 0);

  // 현재 페이지 인덱스를 저장할 변수
  int _currentPage = 0;
  int get currentPage => _currentPage;

  final int _maxPage = 4;
  int get maxPage => _maxPage;

  // 페이지 인덱스를 업데이트하고 UI에 알리는 메서드
  void updatePage(int newPage) {
    if (_currentPage != newPage) {
      _currentPage = newPage;
      notifyListeners();
    }
  }

  // PageController dispose
  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
