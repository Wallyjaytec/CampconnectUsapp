import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.showIcon = true,
    this.iconSize = 40,
  });
  final double? width;
  final double? height;
  final double borderRadius;
  final bool showIcon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).dividerColor.withValues(alpha: 0.15);
    final highlight = Theme.of(context).dividerColor.withValues(alpha: 0.30);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: showIcon
            ? Center(
                child: Opacity(
                  opacity: 0.35,
                  child: Icon(
                    Iconsax.shopping_cart,
                    size: iconSize,
                    color: Colors.grey,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class ShimmerCircle extends StatelessWidget {
  const ShimmerCircle({
    super.key,
    required this.diameter,
    this.showIcon = true,
    this.iconSize = 24,
  });
  final double diameter;
  final bool showIcon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).dividerColor.withValues(alpha: 0.15);
    final highlight = Theme.of(context).dividerColor.withValues(alpha: 0.30);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(color: base, shape: BoxShape.circle),
        child: showIcon
            ? Center(
                child: Opacity(
                  opacity: 0.35,
                  child: Icon(
                    Iconsax.shopping_cart,
                    size: iconSize,
                    color: Colors.grey,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
