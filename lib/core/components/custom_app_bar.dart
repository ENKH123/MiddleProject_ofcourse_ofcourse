import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? iconColor;
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
      backgroundColor: backgroundColor ?? cs.surface,
      foregroundColor: cs.onSurface,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
        icon: Icon(Icons.arrow_back, color: cs.onSurface),
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