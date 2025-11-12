import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/core/managers/supabase_manager.dart';
import 'package:of_course/core/models/gu_model.dart';
import 'package:of_course/core/models/tags_moedl.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const double _buttonHeight = 36.0;
  static const double _spacing = 8.0;
  static const Color _defaultBackgroundColor = Color(0xFFFAFAFA);
  static const Color _randomButtonColor = Color(0xFF003366);
  static const int _maxNotificationCount = 99;

  final GuModel? selectedGu;
  final List<GuModel> guList;
  final Function(GuModel)? onGuChanged;
  final VoidCallback? onRandomPressed;
  final VoidCallback? onNotificationPressed;
  final int? unreadAlertCount;
  final Color? backgroundColor;
  final Set<TagModel>? selectedCategories;

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
    return AppBar(
      backgroundColor: backgroundColor ?? _defaultBackgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildRegionSelector(),
              const SizedBox(width: _spacing),
              _buildRandomButton(context),
            ],
          ),
          _buildNotificationIcon(),
        ],
      ),
    );
  }

  /// 지역 선택 드롭다운
  Widget _buildRegionSelector() {
    return Container(
      height: _buttonHeight,
      padding: const EdgeInsets.symmetric(horizontal: _spacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_spacing),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButton<GuModel>(
        value: selectedGu,
        underline: const SizedBox(),
        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[700]),
        items: _buildDropdownItems(),
        onChanged: _handleGuChanged,
      ),
    );
  }

  List<DropdownMenuItem<GuModel>> _buildDropdownItems() {
    return guList
        .map(
          (gu) => DropdownMenuItem(
        value: gu,
        child: Text(
          gu.name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    )
        .toList();
  }

  void _handleGuChanged(GuModel? value) {
    if (value != null) {
      onGuChanged?.call(value);
    }
  }

  Widget _buildRandomButton(BuildContext context) {
    return SizedBox(
      height: _buttonHeight,
      child: ElevatedButton(
        onPressed: () => _onRandomButtonPressed(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: _randomButtonColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_spacing),
          ),
          elevation: 0,
        ),
        child: const Text(
          'random',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _onRandomButtonPressed(BuildContext context) {
    if (onRandomPressed != null) {
      onRandomPressed!();
    } else {
      _handleRandomPressed(context);
    }
  }

  /// 랜덤 코스 가져오기 및 상세 화면으로 이동
  Future<void> _handleRandomPressed(BuildContext context) async {
    if (!context.mounted) return;

    try {
      final userRowId = await SupabaseManager.shared.getMyUserRowId();
      final likedCourseIds = await _getLikedCourseIds(userRowId);
      final randomCourseId = await _getRandomCourseId(likedCourseIds);

      if (randomCourseId != null && context.mounted) {
        _navigateToDetail(context, randomCourseId, userRowId ?? '');
      } else if (context.mounted) {
        _showErrorMessage(context, '랜덤 코스를 찾을 수 없습니다.');
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorMessage(context, '랜덤 코스를 가져오는 중 오류가 발생했습니다.');
      }
    }
  }

  /// 좋아요한 코스 ID 목록 가져오기
  Future<List<int>> _getLikedCourseIds(String? userRowId) async {
    if (userRowId == null) return [];
    return await SupabaseManager.shared.getLikedCourseIds(userRowId);
  }

  /// 랜덤 코스 ID 가져오기 (태그 기반 또는 완전 랜덤)
  Future<int?> _getRandomCourseId(List<int> likedCourseIds) async {
    // 태그 기반 랜덤 시도
    if (_hasSelectedCategories) {
      final selectedTagNames = _getSelectedTagNames();
      final tagBasedCourseId =
      await SupabaseManager.shared.getRandomCourseByTags(
        selectedTagNames,
        likedCourseIds,
      );
      if (tagBasedCourseId != null) return tagBasedCourseId;
    }

    // 완전 랜덤
    return await SupabaseManager.shared.getRandomCourse(
      excludeCourseIds: likedCourseIds,
    );
  }

  bool get _hasSelectedCategories =>
      selectedCategories != null && selectedCategories!.isNotEmpty;

  List<String> _getSelectedTagNames() {
    return selectedCategories!.map((tag) => tag.name).toList();
  }

  /// 코스 상세 화면으로 이동
  void _navigateToDetail(BuildContext context, int courseId, String userId) {
    context.push(
      '/detail',
      extra: {'courseId': courseId, 'userId': userId},
    );
  }

  /// 에러 메시지 표시
  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
      children: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: Colors.grey[700]),
          onPressed: onNotificationPressed,
        ),
        if (_hasUnreadNotifications)
          _buildNotificationBadge(),
      ],
    );
  }

  bool get _hasUnreadNotifications =>
      unreadAlertCount != null && unreadAlertCount! > 0;

  Widget _buildNotificationBadge() {
    return Positioned(
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
            _getNotificationCountText(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _getNotificationCountText() {
    if (unreadAlertCount == null) return '0';
    return unreadAlertCount! > _maxNotificationCount
        ? '$_maxNotificationCount+'
        : unreadAlertCount.toString();
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
