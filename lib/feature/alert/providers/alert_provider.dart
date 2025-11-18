import 'dart:async';

import 'package:flutter/material.dart';
import 'package:of_course/feature/alert/data/alert_data_source.dart';
import 'package:of_course/feature/alert/models/alert_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertProvider extends ChangeNotifier {
  // 알림 목록
  List<AlertModel>? _alerts;
  List<AlertModel>? get alerts => _alerts;

  final currentUser = Supabase.instance.client.auth.currentUser;

  String? _publicUserId;
  String? get publicUserId => _publicUserId;

  late RealtimeChannel? channel;

  AlertProvider() {
    _init();
  }

  Future<void> _init() async {
    channel = _subscribeAlertEvent();
    _publicUserId = await AlertDataSource.instance.fetchPublicUserId(
      currentUser?.email ?? "",
    );
    // 처음 뷰모델 생성시 알림 불러오기
    fetchAlerts();
  }

  @override
  void dispose() {
    if (channel != null) {
      channel?.unsubscribe();
    }
    super.dispose();
  }

  // 알림 불러오기
  Future<void> fetchAlerts() async {
    _alerts = await AlertDataSource.instance.fetchAlerts();
    notifyListeners();
  }

  // 알림 삭제
  Future<void> deleteAlert(int alertId) async {
    await AlertDataSource.instance.deleteAlert(alertId);
    fetchAlerts();
  }

  // 알림 전체 삭제
  Future<void> deleteAllAlert() async {
    await AlertDataSource.instance.deleteAllAlert();
    fetchAlerts();
  }

  void unsubscribeRealtime() {
    channel?.unsubscribe();
  }

  void resubscribeRealtime() {
    channel?.unsubscribe();
    channel = _subscribeAlertEvent();
    fetchAlerts();
  }

  // 실시간 감지
  RealtimeChannel? _subscribeAlertEvent() {
    if (publicUserId != null) {
      // 데이터 변경(추가, 삭제) 될 때마다 알림 불러오기
      return Supabase.instance.client
          .channel('listen_alert')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'alert',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'to_user_id',
              value: publicUserId,
            ),
            callback: (payload) {
              fetchAlerts();
              // _alerts?.add(payload.newRecord as AlertModel);
              notifyListeners();
            },
          )
          .subscribe();
    } else {
      return null;
    }
  }
}
