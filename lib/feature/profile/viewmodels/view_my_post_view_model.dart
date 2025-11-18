import 'package:flutter/material.dart';
import 'package:of_course/core/managers/supabase_manager.dart';

class ViewMyPostViewModel extends ChangeNotifier {
  final SupabaseManager supabase = SupabaseManager.shared;

  List<Map<String, dynamic>> myPosts = [];
  String userId;

  ViewMyPostViewModel(this.userId) {
    loadMyPosts();
  }

  Future<void> loadMyPosts() async {
    myPosts = await supabase.getMyCourses(userId);
    notifyListeners();
  }
}
