import 'package:flutter/material.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/alert_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertViewModel extends ChangeNotifier {
  List<AlertModel>? _alerts;
  List<AlertModel>? get alerts => _alerts;

  late RealtimeChannel channel;

  AlertViewModel() {
    fetchAlerts();
    channel = _subscribeAlertEvent();
  }

  @override
  void dispose() {
    channel.unsubscribe();
    super.dispose();
  }

  Future<void> fetchAlerts() async {
    _alerts = await SupabaseManager.shared.fetchAlerts();
    notifyListeners();
  }

  Future<void> deleteAlert(int alertId) async {
    await SupabaseManager.shared.deleteAlert(alertId);
  }

  RealtimeChannel _subscribeAlertEvent() {
    return SupabaseManager.shared.supabase
        .channel('listen_alert')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'alert',
          callback: (payload) {
            final newAlert = payload.newRecord;
            final AlertModel newChatMessage = AlertModel.fromJson(newAlert);
            print('Change received: ${payload.toString()}');
            _alerts?.add(newChatMessage);
            notifyListeners();
          },
        )
        .subscribe();
  }
}
