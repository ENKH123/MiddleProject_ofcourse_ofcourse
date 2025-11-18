import 'package:flutter/material.dart';
import 'package:of_course/core/models/tag_color_model.dart';
import 'package:of_course/feature/course/models/course_detail_models.dart';

class CourseDetailSets extends StatelessWidget {
  final List<CourseSet> sets;
  final Map<String, GlobalKey> setCardKeys;
  final Function(String) onImageTap;
  final Function(String) onAddressTap;

  const CourseDetailSets({
    super.key,
    required this.sets,
    required this.setCardKeys,
    required this.onImageTap,
    required this.onAddressTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: sets.asMap().entries.map((entry) {
        final i = entry.key;
        final set = entry.value;
        return Padding(
          key: setCardKeys[set.setId],
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: i < sets.length - 1 ? 24 : 0,
          ),
          child: _SetCard(
            set: set,
            onImageTap: onImageTap,
            onAddressTap: onAddressTap,
          ),
        );
      }).toList(),
    );
  }
}

class _SetCard extends StatelessWidget {
  final CourseSet set;
  final Function(String) onImageTap;
  final Function(String) onAddressTap;

  const _SetCard({
    required this.set,
    required this.onImageTap,
    required this.onAddressTap,
  });

  @override
  Widget build(BuildContext context) {
    final hex = TagColorModel.getColorHex(set.tag);
    final Color tagColor = hex != null
        ? Color(int.parse(hex.replaceFirst('#', ''), radix: 16) + 0xFF000000)
        : Colors.grey[200]!;

    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceBright,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (set.setImages.isNotEmpty)
              SizedBox(
                height: 150,
                child: Row(
                  children: set.setImages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final url = entry.value;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onImageTap(url),
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index < set.setImages.length - 1 ? 8 : 0,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: double.infinity,
                              height: 150,
                              child: Image.network(
                                url,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 150,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 16),
            if (set.setAddress.isNotEmpty)
              GestureDetector(
                onTap: () => onAddressTap(set.setId),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: cs.surfaceContainerHigh,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        set.setAddress,
                        style: TextStyle(color: cs.surfaceContainerHigh),
                      ),
                    ),
                  ],
                ),
              ),
            if (set.setAddress.isNotEmpty) const SizedBox(height: 8),
            Text(
              set.setDescription,
              style: TextStyle(color: cs.surfaceContainerHigh),
            ),
            if (set.tag.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tagColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#${set.tag}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff030303),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
