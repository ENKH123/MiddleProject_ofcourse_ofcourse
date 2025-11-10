import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/gu_model.dart';
import 'package:of_course/core/models/tags_moedl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GuModel selectedGu;
  final List<GuModel> guList;
  final Function(GuModel)? onGuChanged;
  final VoidCallback? onRandomPressed;
  final VoidCallback? onNotificationPressed;
  final int? unreadAlertCount;
  final Color? backgroundColor;
  final Set<TagModel>? selectedCategories; // 선택된 태그들

  const HomeAppBar({
    super.key,
    required this.selectedGu,
    required this.guList,
    this.onGuChanged,
    this.onRandomPressed,
    this.onNotificationPressed,
    this.unreadAlertCount,
    this.backgroundColor,
    this.selectedCategories,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBackgroundColor = backgroundColor ?? const Color(0xFFFAFAFA);

    return AppBar(
      backgroundColor: defaultBackgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildRegionSelector(context),
              const SizedBox(width: 8),
              _buildRandomButton(context),
            ],
          ),
          _buildNotificationIcon(context),
        ],
      ),
    );
  }

  /// ✅ 지역 선택 드롭다운
  Widget _buildRegionSelector(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButton<GuModel>(
        value: selectedGu,
        underline: const SizedBox(),
        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[700]),
        items: guList.map((gu) {
          return DropdownMenuItem(
            value: gu,
            child: Text(
              gu.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null && onGuChanged != null) {
            onGuChanged!(value);
          }
        },
      ),
    );
  }

  Widget _buildRandomButton(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: () {
          if (onRandomPressed != null) {
            onRandomPressed!();
          } else {
            _handleRandomPressed(context);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF003366),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: const Text(
          'random',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// 랜덤 코스 가져오기 및 상세 화면으로 이동
  Future<void> _handleRandomPressed(BuildContext context) async {
    try {
      // 현재 사용자 ID 가져오기
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('오류')),
        );
        return;
      }

      // 좋아요한 코스 목록 가져오기
      final likedCourseIds = await SupabaseManager.shared.getLikedCourseIds(currentUser.id);

      // 선택된 태그가 있으면 태그 기반 랜덤, 없으면 완전 랜덤
      int? randomCourseId;
      if (selectedCategories != null && selectedCategories!.isNotEmpty) {
        final selectedTagNames = selectedCategories!.map((tag) => tag.name).toList();
        randomCourseId = await SupabaseManager.shared.getRandomCourseByTags(
          selectedTagNames,
          likedCourseIds,
        );
      }

      // 태그 기반으로 못 찾았거나 태그가 없으면 완전 랜덤
      if (randomCourseId == null) {
        randomCourseId = await SupabaseManager.shared.getRandomCourse(
          excludeCourseIds: likedCourseIds,
        );
      }

      if (randomCourseId != null && context.mounted) {
        // 코스 상세 화면으로 이동
        context.push('/detail?id=$randomCourseId');
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('랜덤 코스를 찾을 수 없습니다.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('랜덤 코스 가져오기 오류: $e')),
        );
      }
    }
  }

  Widget _buildNotificationIcon(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: Colors.grey[700]),
          onPressed: onNotificationPressed,
        ),
        if (unreadAlertCount != null && unreadAlertCount! > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Center(
                child: Text(
                  unreadAlertCount! > 99 ? '99+' : unreadAlertCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
