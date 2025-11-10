import 'package:flutter/material.dart';
import 'package:of_course/core/models/tag_color_model.dart';

class PostCard extends StatelessWidget {
  final String title;
  final List<String> tags;
  final List<String>? imageUrls;
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
    final List<String?> displayImages = List.generate(3, (i) {
      if (imageUrls != null &&
          i < imageUrls!.length &&
          imageUrls![i] != null &&
          imageUrls![i]!.isNotEmpty) {
        return imageUrls![i];
      }
      return null;
    });

    return Container(
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
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('#$tag', style: const TextStyle(fontSize: 12)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
