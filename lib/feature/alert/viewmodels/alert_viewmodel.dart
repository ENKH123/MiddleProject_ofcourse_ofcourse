import 'package:flutter/material.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/alert_model.dart';

class AlertViewModel extends ChangeNotifier {
  List<AlertModel>? _alerts;
  List<AlertModel>? get alerts => _alerts;

  AlertViewModel() {
    fetchAlerts();
  }

  Future<void> fetchAlerts() async {
    _alerts = await SupabaseManager.shared.fetchAlerts();
    notifyListeners();
  }
}
