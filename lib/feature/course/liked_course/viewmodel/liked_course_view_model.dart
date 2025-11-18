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
}
