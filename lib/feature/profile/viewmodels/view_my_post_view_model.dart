import 'package:flutter/material.dart';
import 'package:of_course/feature/profile/data/profile_data_source.dart';

class ViewMyPostViewModel extends ChangeNotifier {
  List<Map<String, dynamic>> myPosts = [];
  String userId;

  ViewMyPostViewModel(this.userId) {
    loadMyPosts();
  }

  Future<void> loadMyPosts() async {
    myPosts = await ProfileDataSource.instance.getMyCourses(userId);
    notifyListeners();
  }
}
