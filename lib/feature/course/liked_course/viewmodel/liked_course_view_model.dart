import 'package:flutter/material.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/tags_moedl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LikedCourseViewModel extends ChangeNotifier {
  final SupabaseManager supabase = SupabaseManager.shared;

  List<TagModel> tagList = [];
  Set<TagModel> selectedCategories = {};
  List<Map<String, dynamic>> courseList = [];

  bool isLoading = false;
  DateTime? lastBackPressTime;
  LikedCourseViewModel() {
    init();
  }

  Future<void> init() async {
    await _loadTags();
    await loadLikedCourses();
  }

  // -----------------------------
  // Load Tags
  // -----------------------------
  Future<void> _loadTags() async {
    final tags = await supabase.getTags();
    tagList = tags;
    notifyListeners();
  }

  // -----------------------------
  // Load Liked Courses
  // -----------------------------
  Future<void> loadLikedCourses() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint("⚠️ 로그인된 유저 없음");
      return;
    }

    isLoading = true;
    notifyListeners();

    final selectedTagNames = selectedCategories.map((t) => t.name).toList();

    final data = await supabase.getLikedCourses(
      selectedTagNames: selectedTagNames,
    );

    courseList = data;

    isLoading = false;
    notifyListeners();
  }

  // -----------------------------
  // Tag Selection
  // -----------------------------
  bool isSelected(TagModel tag) => selectedCategories.contains(tag);

  void toggleCategory(TagModel tag) {
    if (isSelected(tag)) {
      selectedCategories.remove(tag);
    } else {
      selectedCategories.add(tag);
    }

    notifyListeners();
    loadLikedCourses();
  }

  bool handleWillPop() {
    final now = DateTime.now();

    // 첫 클릭 → 초기화 후 종료 막기
    if (lastBackPressTime == null) {
      lastBackPressTime = now;
      return false;
    }

    // 2초 지난 경우 → 다시 초기화 후 종료 막기
    if (now.difference(lastBackPressTime!) > const Duration(seconds: 2)) {
      lastBackPressTime = now;
      return false;
    }

    // 2초 내 두 번째 클릭 → 종료 허용
    return true;
  }
}
