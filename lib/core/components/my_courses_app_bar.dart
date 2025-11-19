import 'package:flutter/material.dart';

enum SeoulDistrict {
  gangnam,
  gangdong,
  gangbuk,
  gangseo,
  gwanak,
  gwangjin,
}

extension SeoulDistrictExtension on SeoulDistrict {
  String get displayName {
    switch (this) {
      case SeoulDistrict.gangnam:
        return '강남구';
      case SeoulDistrict.gangdong:
        return '강동구';
      case SeoulDistrict.gangbuk:
        return '강북구';
      case SeoulDistrict.gangseo:
        return '강서구';
      case SeoulDistrict.gwanak:
        return '관악구';
      case SeoulDistrict.gwangjin:
        return '광진구';
    }
  }
}

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final SeoulDistrict selectedDistrict;
  final Function(SeoulDistrict)? onDistrictChanged;
  final VoidCallback? onRandomPressed;
  final VoidCallback? onNotificationPressed;
  final int? unreadAlertCount;
  final Color? backgroundColor;

  const HomeAppBar({
    super.key,
    required this.selectedDistrict,
    this.onDistrictChanged,
    this.onRandomPressed,
    this.onNotificationPressed,
    this.unreadAlertCount,
    this.backgroundColor,
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
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

  Widget _buildRegionSelector(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: PopupMenuButton<SeoulDistrict>(
          offset: const Offset(0, 50),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedDistrict.displayName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: Colors.grey[700],
              ),
            ],
          ),
          itemBuilder: (context) => SeoulDistrict.values.map((district) {
            return PopupMenuItem<SeoulDistrict>(
              value: district,
              child: Text(district.displayName),
            );
          }).toList(),
          onSelected: (value) {
            if (onDistrictChanged != null) {
              onDistrictChanged!(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildRandomButton(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onRandomPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF003366),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
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

  Widget _buildNotificationIcon(BuildContext context) {
    return SizedBox(
      height: 36,
      width: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: Colors.grey[700],
                size: 24,
              ),
              onPressed: onNotificationPressed,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          if (unreadAlertCount != null && unreadAlertCount! > 0)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    unreadAlertCount! > 99 ? '99+' : unreadAlertCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}