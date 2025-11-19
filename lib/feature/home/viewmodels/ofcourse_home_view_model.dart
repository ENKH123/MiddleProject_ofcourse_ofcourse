import 'package:flutter/material.dart';
import 'package:of_course/core/data/core_data_source.dart';
import 'package:of_course/core/models/tags_moedl.dart';
import 'package:of_course/feature/home/data/home_data_source.dart';
import 'package:of_course/feature/home/models/gu_model.dart';

class OfcourseHomeViewModel extends ChangeNotifier {
  GuModel? selectedGu;
  List<GuModel> guList = [];

  List<TagModel> tagList = [];
  Set<TagModel> selectedCategories = {};

  List<Map<String, dynamic>> courseList = [];

  bool isRefreshing = false;

  // 🔥 추가: 뒤로가기 시간 저장
  DateTime? lastBackPressTime;

  OfcourseHomeViewModel() {
    lastBackPressTime = null;
    init();
  }

  Future<void> init() async {
    await loadGu();
    await loadTags();
    await loadCourses();
  }

  Future<void> loadGu() async {
    guList = await HomeDataSource.instance.getGuList();
    selectedGu = null;
    notifyListeners();
  }

  Future<void> loadTags() async {
    tagList = await CoreDataSource.instance.getTags();
    notifyListeners();
  }

  Future<void> loadCourses() async {
    final guId = selectedGu?.id;
    final tagNames = selectedCategories.map((e) => e.name).toList();

    courseList = await HomeDataSource.instance.getCourseList(
      guId: guId,
      selectedTagNames: tagNames.isEmpty ? null : tagNames,
    );
    notifyListeners();
  }

  void changeGu(GuModel? gu) {
    selectedGu = gu;
    loadCourses();
  }

  void toggleCategory(TagModel tag) {
    if (selectedCategories.contains(tag)) {
      selectedCategories.remove(tag);
    } else {
      selectedCategories.add(tag);
    }
    notifyListeners();
    loadCourses();
  }

  Future<void> refreshAll() async {
    isRefreshing = true;
    selectedGu = null;
    selectedCategories.clear();
    notifyListeners();

    await init();

    isRefreshing = false;
    notifyListeners();
  }

  bool handleWillPop() {
    final now = DateTime.now();

    if (lastBackPressTime == null ||
        now.difference(lastBackPressTime!) > const Duration(seconds: 2)) {
      lastBackPressTime = now;
      return false; // 종료 막기
    }

    return true; // 종료 허용
  }
}
