import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileDataSource {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMyCourses(String userId) async {
    // 내가 작성한 코스 + 각 세트 JOIN해서 한 번에 가져오기
    final rows = await supabase
        .from('courses')
        .select('''
        id,
        title,
        created_at,

        set_01:course_sets!courses_set_01_fkey (
          img_01, img_02, img_03, tags(type)
        ),
        set_02:course_sets!courses_set_02_fkey (
          img_01, img_02, img_03, tags(type)
        ),
        set_03:course_sets!courses_set_03_fkey (
          img_01, img_02, img_03, tags(type)
        ),
        set_04:course_sets!courses_set_04_fkey (
          img_01, img_02, img_03, tags(type)
        ),
        set_05:course_sets!courses_set_05_fkey (
          img_01, img_02, img_03, tags(type)
        )
      ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final List<Map<String, dynamic>> result = [];

    for (final c in rows as List) {
      final List<String> images = [];
      final Set<String> tags = {};

      for (final key in ['set_01', 'set_02', 'set_03', 'set_04', 'set_05']) {
        final set = c[key];
        if (set == null) continue;

        for (final img in [set['img_01'], set['img_02'], set['img_03']]) {
          if (img != null && img.toString().isNotEmpty) {
            images.add(img.toString());
          }
        }

        final tagInfo = set['tags'];
        if (tagInfo != null && tagInfo['type'] != null) {
          tags.add(tagInfo['type']);
        }
      }

      result.add({
        'id': c['id'],
        'title': c['title'],
        'images': images.take(3).toList(),
        'tags': tags.toList(),
      });
    }

    return result;
  }
}
