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
    this.logoSize = 28,
    this.useText = false,
    this.text = 'CCU',
  });
  final double? width;
  final double? height;
  final double borderRadius;
  final bool showLogo;
  final double logoSize;
  final bool useText;
  final String text;

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
                  child: useText
                      ? Text(
                          text,
                          style: TextStyle(
                            fontSize: logoSize - 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        )
                      : Image.asset(
                          AppAssets.appIcon,
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.contain,
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
    this.logoSize = 16,
    this.useText = false,
    this.text = 'CCU',
  });
  final double diameter;
  final bool showLogo;
  final double logoSize;
  final bool useText;
  final String text;

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
                  child: useText
                      ? Text(
                          text,
                          style: TextStyle(
                            fontSize: logoSize - 4,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        )
                      : Image.asset(
                          AppAssets.appIcon,
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.contain,
                        ),
                ),
              )
            : null,
      ),
    );
  }
}
