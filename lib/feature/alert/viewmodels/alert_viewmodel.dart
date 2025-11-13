import 'dart:async';

import 'package:flutter/material.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/alert_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertViewModel extends ChangeNotifier {
  // 알림 목록
  List<AlertModel>? _alerts;
  List<AlertModel>? get alerts => _alerts;

  late RealtimeChannel channel;

  AlertViewModel() {
    channel = _subscribeAlertEvent();
  }

  @override
  void dispose() {
    channel.unsubscribe();
    super.dispose();
  }

  // 알림 불러오기
  Future<void> fetchAlerts() async {
    _alerts = await SupabaseManager.shared.fetchAlerts();
    notifyListeners();
  }

  // 알림 삭제
  Future<void> deleteAlert(int alertId) async {
    await SupabaseManager.shared.deleteAlert(alertId);
    fetchAlerts();
  }

  void unsubscribeRealtime() {
    channel.unsubscribe();
  }

  void resubscribeRealtime() {
    channel.unsubscribe();
    channel = _subscribeAlertEvent();
  }

  // 실시간 감지
  RealtimeChannel _subscribeAlertEvent() {
    // 처음 뷰모델 생성시 알림 불러오기
    fetchAlerts();
    // 데이터 변경(추가, 삭제) 될 때마다 알림 불러오기
    return SupabaseManager.shared.supabase
        .channel('listen_alert')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'alert',
          callback: (payload) {
            print("payload : $payload");
            fetchAlerts();
          },
        )
        .subscribe();
  }
}
