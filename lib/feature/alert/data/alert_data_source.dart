import 'package:of_course/core/data/core_data_source.dart';
import 'package:of_course/feature/alert/models/alert_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertDataSource {
  AlertDataSource._();
  static final AlertDataSource instance = AlertDataSource._();

  final supabase = Supabase.instance.client;

  Future<String?> fetchPublicUserId(String gmail) async {
    final Map<String, dynamic>? data = await supabase
        .from("users")
        .select('id')
        .eq('email', gmail)
        .maybeSingle();
    if (data == null) {
      return null;
    }

    final userId = data['id'].toString();
    return userId;
  }

  // 알림 전체 삭제
  Future<void> deleteAllAlert() async {
    final userEmail = supabase.auth.currentUser?.email ?? "";
    final userId = await fetchPublicUserId(userEmail);
    await supabase.from('alert').delete().eq('to_user_id', userId ?? "");
  }

  // 알림 목록 조회
  Future<List<AlertModel>?> fetchAlerts() async {
    final currentUser = supabase.auth.currentUser;
    final user = await CoreDataSource.instance.fetchPublicUser(
      currentUser?.email ?? "",
    );

    final data = await supabase
        .from('alert')
        .select('*, users!from_user_id(nickname)')
        .eq('to_user_id', user?.id ?? "")
        .neq('from_user_id', user?.id ?? "")
        .order('created_at', ascending: false);
    return (data as List).map((e) => AlertModel.fromJson(e)).toList();
  }

  // 알림 삭제
  Future<void> deleteAlert(int alertId) async {
    await supabase.from('alert').delete().eq('id', alertId);
  }
}
