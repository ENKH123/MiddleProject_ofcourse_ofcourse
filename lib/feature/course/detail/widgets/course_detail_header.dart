import 'package:flutter/material.dart';
import 'package:of_course/core/models/tag_color_model.dart';
import 'package:of_course/feature/course/detail/utils/date_utils.dart';
import 'package:of_course/feature/course/models/course_detail_models.dart';

class CourseDetailHeader extends StatelessWidget {
  final CourseDetail courseDetail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onReport;

  const CourseDetailHeader({
    super.key,
    required this.courseDetail,
    required this.onEdit,
    required this.onDelete,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  courseDetail.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (courseDetail.isAuthor) ...[
                TextButton(onPressed: onEdit, child: const Text('수정')),
                TextButton(
                  onPressed: onDelete,
                  child: const Text('삭제', style: TextStyle(color: Colors.red)),
                ),
              ] else if (onReport != null) ...[
                TextButton(onPressed: onReport, child: const Text('신고')),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '작성자: ${courseDetail.authorName}',
                style: TextStyle(color: cs.surfaceContainerHighest),
              ),
              const SizedBox(width: 16),
              Text(
                '작성일: ${CourseDateUtils.formatDate(courseDetail.createdAt)}',
                style: TextStyle(color: cs.surfaceContainerHighest),
              ),
            ],
          ),
          if (courseDetail.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: courseDetail.tags.map((tag) {
                final hex = TagColorModel.getColorHex(tag);
                final bg = hex != null
                    ? Color(
                        int.parse(hex.replaceFirst('#', ''), radix: 16) +
                            0xFF000000,
                      )
                    : Colors.grey.shade200;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#$tag',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff030303),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
