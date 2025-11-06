import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final String title;
  final List<String> tags;
  final List<String>? imageUrls; // 이미지 있을 수도, 없을 수도
  final int? likeCount;
  final int? commentCount;

  const PostCard({
    Key? key,
    required this.title,
    required this.tags,
    this.imageUrls,
    this.likeCount,
    this.commentCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasImages = imageUrls != null && imageUrls!.isNotEmpty;
    final hasLikesOrComments = (likeCount != null && commentCount != null);

    return Container(
      margin: const EdgeInsets.only(bottom: 16), // 🔹 게시물 간 간격
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
          /// 🔸 제목
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          /// 🔸 이미지 박스 (옵션)
          if (hasImages)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: imageUrls!.take(3).map((_) {
                return Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }).toList(),
            ),

          if (hasImages) const SizedBox(height: 8),

          /// 🔸 태그
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#$tag',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blueAccent,
                  ),
                ),
              );
            }).toList(),
          ),

          /// 🔸 좋아요 / 댓글 (옵션)
          if (hasLikesOrComments) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.favorite_border, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${likeCount ?? 0}', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                const Icon(
                  Icons.comment_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  '${commentCount ?? 0}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
