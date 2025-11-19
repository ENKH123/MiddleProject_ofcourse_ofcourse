import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:of_course/feature/report/models/report_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportDataSource {
  ReportDataSource._();
  static final ReportDataSource instance = ReportDataSource._();
  final supabase = Supabase.instance.client;

  Future<void> submitReport({
    required String targetId,
    required ReportTargetType targetType,
    required ReportReason reportReason,
    required String reason,
    required List<String> imagePaths,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final List<String> imageUrls = [];
      for (int i = 0; i < imagePaths.length && i < 3; i++) {
        final imageFile = File(imagePaths[i]);
        if (await imageFile.exists()) {
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final filePath = '$userId/$fileName';

          await supabase.storage.from('report').upload(filePath, imageFile);

          final imageUrl = supabase.storage
              .from('report')
              .getPublicUrl(filePath);

          imageUrls.add(imageUrl);
        }
      }

      final targetTypeString = targetType == ReportTargetType.course
          ? 'course'
          : 'comment';

      await supabase.from('report').insert({
        'target_id': targetId,
        'target_type': targetTypeString,
        'report_type': reportReason.label,
        'reason': reason,
        'img_01': imageUrls.isNotEmpty ? imageUrls[0] : null,
        'img_02': imageUrls.length > 1 ? imageUrls[1] : null,
        'img_03': imageUrls.length > 2 ? imageUrls[2] : null,
      });
    } catch (e) {
      debugPrint('신고 제출 오류: $e');
      rethrow;
    }
  }
}
