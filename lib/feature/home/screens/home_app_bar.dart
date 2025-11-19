import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:of_course/core/data/core_data_source.dart';
import 'package:of_course/core/models/tags_moedl.dart';
import 'package:of_course/feature/alert/providers/alert_provider.dart';
import 'package:of_course/feature/home/models/gu_model.dart';
import 'package:provider/provider.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const double _buttonHeight = 36.0;
  static const double _spacing = 8.0;
  // static const Color _defaultBackgroundColor = Color(0xFFFAFAFA);
  // static const Color _randomButtonColor = Color(0xFF003366);
  static const int _maxNotificationCount = 99;

  final GuModel? selectedGu;
  final List<GuModel> guList;
  final Function(GuModel?)? onGuChanged;
  final VoidCallback? onRandomPressed;
  final VoidCallback? onNotificationPressed;
  final Color? backgroundColor;
  final Set<TagModel>? selectedCategories;

  const HomeAppBar({
    super.key,
    required this.selectedGu,
    required this.guList,
    this.onGuChanged,
    this.onRandomPressed,
    this.onNotificationPressed,
    this.backgroundColor,
    this.selectedCategories,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
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

  Widget _buildRegionSelector() {
    return Builder(
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Container(
          height: _buttonHeight,
          padding: const EdgeInsets.symmetric(horizontal: _spacing),
          decoration: BoxDecoration(
            //color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(_spacing),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButton<GuModel>(
            value: selectedGu,
            hint: const Text(
              '전체',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            underline: const SizedBox(),
            icon: Icon(Icons.keyboard_arrow_down, color: cs.onBackground),
            items: _buildDropdownItems(),
            onChanged: _handleGuChanged,
          ),
        );
      },
    );
  }

  List<DropdownMenuItem<GuModel>> _buildDropdownItems() {
    final items = <DropdownMenuItem<GuModel>>[
      const DropdownMenuItem<GuModel>(
        value: null,
        child: Text(
          '전체',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    ];

    items.addAll(
      guList.map(
        (gu) => DropdownMenuItem<GuModel>(
          value: gu,
          child: Text(
            gu.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );

    return items;
  }

  void _handleGuChanged(GuModel? value) {
    onGuChanged?.call(value);
  }

  Widget _buildRandomButton(BuildContext context) {
    return SizedBox(
      height: _buttonHeight,
      child: ElevatedButton(
        onPressed: () => _onRandomButtonPressed(context),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_spacing),
          ),
          elevation: 0,
        ),
        child: const Text(
          '코스 추천',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _onRandomButtonPressed(BuildContext context) async {
    if (onRandomPressed != null) {
      onRandomPressed!();
      return;
    }

    try {
      final userRowId = await CoreDataSource.instance.getMyUserRowId();

      if (userRowId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
        return;
      }

      // 온보딩 화면으로 이동
      context.push('/onboarding');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('추천 중 오류가 발생했습니다: $e')));
    }
  }

  String _buildRecommendationReason(
    Map<String, dynamic> summary,
    Map<String, dynamic> rec,
  ) {
    final percent = rec['similarity_percent'] ?? 0;

    final matchedTags = rec['matched_tags'] as List<dynamic>? ?? [];
    final matchedGus = rec['matched_gus'] as List<dynamic>? ?? [];

    String? tagPart;
    if (matchedTags.isNotEmpty) {
      final names = matchedTags
          .map((t) => t['name'])
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
      if (names.isNotEmpty) {
        tagPart = names.join(', ');
      }
    }

    String? guPart;
    if (matchedGus.isNotEmpty) {
      final names = matchedGus
          .map((g) => g['name'])
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
      if (names.isNotEmpty) {
        guPart = names.join(', ');
      }
    }

    String sentence = '이 코스는 내 취향과 유사도 $percent%입니다.\n';

    if (tagPart != null) {
      sentence += '최근에 $tagPart 태그 코스를 좋아했고,\n';
    }

    if (guPart != null) {
      sentence += '$guPart관련 코스를 자주 선택해 추천했어요.';
    } else {
      if (sentence.endsWith(',\n')) {
        sentence = sentence.substring(0, sentence.length - 2);
        sentence += '\n';
      }
      sentence += '추천했어요.';
    }

    return sentence;
  }

  Widget _buildNotificationIcon() {
    return Consumer<AlertProvider>(
      builder: (context, alertProvider, child) {
        final alertCount = alertProvider.alerts?.length ?? 0;
        final hasUnreadNotifications = alertCount > 0;

        return Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: Colors.grey[700]),
              onPressed: onNotificationPressed,
            ),
            if (hasUnreadNotifications) _buildNotificationBadge(alertCount),
          ],
        );
      },
    );
  }

  Widget _buildNotificationBadge(int alertCount) {
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
            _getNotificationCountText(alertCount),
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

  String _getNotificationCountText(int alertCount) {
    return alertCount > _maxNotificationCount
        ? '$_maxNotificationCount+'
        : alertCount.toString();
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
