import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:kartly_e_commerce/core/constants/app_assets.dart';

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.showLogo = true,
    this.logoSize = 40,
  });
  final double? width;
  final double? height;
  final double borderRadius;
  final bool showLogo;
  final double logoSize;

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
        child: showLogo
            ? Center(
                child: Opacity(
                  opacity: 0.35,
                  child: Image.asset(
                    AppAssets.appLogo,
                    width: logoSize,
                    height: logoSize,
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
    this.showLogo = true,
    this.logoSize = 24,
  });
  final double diameter;
  final bool showLogo;
  final double logoSize;

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
        child: showLogo
            ? Center(
                child: Opacity(
                  opacity: 0.35,
                  child: Image.asset(
                    AppAssets.appLogo,
                    width: logoSize,
                    height: logoSize,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
