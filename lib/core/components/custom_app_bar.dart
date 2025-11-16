import 'package:flutter/material.dart';

/// 공통 AppBar 컴포넌트
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// AppBar 제목
  final String? title;

  /// 뒤로가기 버튼 표시 여부
  final bool showBackButton;

  /// 뒤로가기 버튼 클릭 시 실행할 콜백
  final VoidCallback? onBackPressed;

  /// AppBar 배경색
  final Color? backgroundColor;

  /// AppBar 아이콘 테마 색상
  final Color? iconColor;

  /// 오른쪽 액션 버튼들
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.iconColor,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final defaultIconColor = iconColor ?? Colors.black;
    final cs = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: cs.background,
      foregroundColor: cs.onBackground,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: cs.onBackground),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : null,
      title: title != null
          ? Text(
              title!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            )
          : null,
      iconTheme: IconThemeData(color: defaultIconColor),
      actions: actions,
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// 더미 데이터 - 테스트 화면 (삭제 가능)

class CustomAppBarTestScreen extends StatelessWidget {
  const CustomAppBarTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: const CustomAppBar(title: 'CustomAppBar 테스트'),
      body: const SizedBox.shrink(),
    );
  }
}
