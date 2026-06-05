import 'package:campconnectus_marketplace/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class SearchHeader extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  const SearchHeader({required this.child, this.height = 40});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final color = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: color
          ? AppColors.darkBackgroundColor
          : AppColors.lightBackgroundColor,
      elevation: overlapsContent ? 2 : 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: SizedBox(height: height, child: child),
      ),
    );
  }

  @override
  double get maxExtent => height + 16;
  @override
  double get minExtent => height + 16;

  @override
  bool shouldRebuild(covariant SearchHeader oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}
