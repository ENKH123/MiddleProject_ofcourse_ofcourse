import 'package:flutter/material.dart';
import 'package:of_course/core/models/tag_color_model.dart';

class PostCard extends StatelessWidget {
  final String title;
  final List<String> tags;
  final List<String>? imageUrls;
  final int? likeCount;
  final int? commentCount;
  final VoidCallback? onTap; // ✅ 상세 페이지 이동 등 클릭 이벤트

  const PostCard({
    Key? key,
    required this.title,
    required this.tags,
    this.imageUrls,
    this.likeCount,
    this.commentCount,
    this.onTap, // ✅ 추가
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 최대 3장까지 이미지 슬롯
    final List<String?> displayImages = List.generate(3, (i) {
      if (imageUrls != null &&
          i < imageUrls!.length &&
          imageUrls![i] != null &&
          imageUrls![i]!.isNotEmpty) {
        return imageUrls![i];
      }
      return null;
    });

    return GestureDetector(
      onTap: onTap, // ✅ 카드 눌렀을 때 이벤트 실행
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // 이미지 3개 슬라이드 느낌
            SizedBox(
              height: 100,
              child: Row(
                children: displayImages.map((url) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: url == null
                            ? Container(color: Colors.grey[300])
                            : Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: Colors.grey[300]),
                              ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

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
                  child: Text('#$tag', style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
            ),

            const SizedBox(height: 6),

            // 좋아요 & 댓글 개수 (옵션)
            if (likeCount != null || commentCount != null)
              Row(
                children: [
                  if (likeCount != null) ...[
                    const Icon(Icons.favorite_border, size: 14),
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
