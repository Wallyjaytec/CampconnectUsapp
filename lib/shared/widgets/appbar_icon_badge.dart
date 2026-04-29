import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class AppBarIconBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final VoidCallback? onTap;
  final double size;
  final Color? bgColor;
  final Color? iconColor;

  const AppBarIconBadge({
    super.key,
    required this.icon,
    required this.count,
    this.onTap,
    this.size = 24,
    this.bgColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color resolvedIcon =
        iconColor ?? Theme.of(context).colorScheme.onPrimary;

    final color = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.transparentColor,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(icon, size: size, color: resolvedIcon),
            ),
          ),
        ),
        Positioned(
          right: -1,
          top: -1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            decoration: BoxDecoration(
              color: color
                  ? AppColors.whiteColor
                  : AppColors.darkBackgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color ? AppColors.blackColor : AppColors.whiteColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
