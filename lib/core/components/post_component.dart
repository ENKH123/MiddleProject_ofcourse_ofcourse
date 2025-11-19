import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:of_course/core/models/tag_color_model.dart';

class PostCard extends StatelessWidget {
  final String title;
  final List<String> tags;
  final List<String>? imageUrls; // 최대 3장
  final int? likeCount;
  final int? commentCount;
  final bool? isLiked;
  final VoidCallback? onTap;

  const PostCard({
    Key? key,
    required this.title,
    required this.tags,
    this.imageUrls,
    this.likeCount,
    this.commentCount,
    this.isLiked,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // 유효 이미지만 필터링 (null, 빈 문자열 제외)
    final List<String> validImages = (imageUrls ?? [])
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceBright,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cs.onBackground,
              ),
            ),

            const SizedBox(height: 8),

            // ⭐ 이미지가 있을 때만 보여줌
            if (validImages.isNotEmpty)
              SizedBox(
                height: 100,
                child: Row(
                  children: List.generate(3, (i) {
                    final url = i < validImages.length ? validImages[i] : null;

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: url == null
                              ? const SizedBox.shrink()
                              : CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.cover,
                                  progressIndicatorBuilder:
                                      (context, url, progress) => Container(
                                        width: double.infinity,
                                        height: 100,
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: progress.progress,
                                          ),
                                        ),
                                      ),
                                  errorWidget: (_, __, error) {
                                    debugPrint("❌ IMAGE ERROR: $url | $error");
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.error,
                                        color: Colors.red,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

            if (validImages.isNotEmpty) const SizedBox(height: 8),

            // 태그 목록
            Wrap(
              spacing: 6,
              children: tags.map((tag) {
                final colorHex = TagColorModel.getColorHex(tag);
                final bgColor = colorHex != null
                    ? Color(
                        int.parse(colorHex.replaceFirst('#', ''), radix: 16) +
                            0xFF000000,
                      )
                    : Colors.grey.shade200;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
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

            const SizedBox(height: 6),

            // 좋아요 & 댓글 개수 표시
            Row(
              children: [
                if (likeCount != null) ...[
                  Icon(
                    isLiked == true ? Icons.favorite : Icons.favorite_border,
                    size: 14,
                    color: isLiked == true ? Colors.red : cs.onBackground,
                  ),
                  const SizedBox(width: 4),
                  Text('$likeCount'),
                ],
                const SizedBox(width: 12),

                if (commentCount != null) ...[
                  const Icon(Icons.chat_bubble_outline, size: 14),
                  const SizedBox(width: 4),
                  Text('$commentCount'),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
