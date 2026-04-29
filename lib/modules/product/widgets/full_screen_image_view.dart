import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/routes/app_routes.dart';

class FullScreenImageView extends StatefulWidget {
  const FullScreenImageView({super.key});

  @override
  State<FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<FullScreenImageView> {
  late final List<String> images;
  late final PageController controller;
  late int index;
  late final Map? _args;
  late final String _heroPrefix;
  late final String _productIdStr;

  @override
  void initState() {
    super.initState();

    final raw = Get.arguments;
    _args = (raw is Map) ? raw : null;

    final List<String> parsedImages = (_args?['images'] is List)
        ? (_args!['images'] as List).cast<String>()
        : const [];

    if (parsedImages.isEmpty && _args?['images'] is String) {
      images = <String>[_args!['images'] as String];
    } else {
      images = parsedImages;
    }

    final int argIndex = (_args?['index'] is int)
        ? (_args?['index'] as int)
        : 0;
    index = images.isEmpty
        ? 0
        : argIndex.clamp(0, images.isNotEmpty ? images.length - 1 : 0);

    controller = PageController(initialPage: index);

    _heroPrefix = (_args?['heroPrefix'] != null)
        ? _args!['heroPrefix'].toString().trim()
        : ((Get.previousRoute == AppRoutes.productDetailsView)
              ? 'product'
              : 'gallery');

    _productIdStr = (_args?['id'] ?? _args?['productId'])?.toString() ?? '';
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (images.isEmpty)
            const Center(
              child: Icon(Iconsax.gallery_remove_copy, color: Colors.white54),
            )
          else
            PageView.builder(
              controller: controller,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => index = i),
              itemBuilder: (_, i) {
                final src = images[i];
                final isAsset =
                    !(src.startsWith('http://') || src.startsWith('https://'));

                final bool enableHero = i == controller.initialPage;

                final String heroTag =
                    (_heroPrefix == 'product' && _productIdStr.isNotEmpty)
                    ? 'product-$_productIdStr-img-$i'
                    : 'gallery-$i';

                final imageWidget = isAsset
                    ? Image.asset(
                        src,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        filterQuality: FilterQuality.high,
                      )
                    : CachedNetworkImage(
                        imageUrl: src,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        filterQuality: FilterQuality.high,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(
                            Iconsax.gallery_remove_copy,
                            color: Colors.white54,
                          ),
                        ),
                      );

                return ClipRect(
                  child: HeroMode(
                    enabled: enableHero,
                    child: Hero(
                      tag: enableHero ? heroTag : 'no-hero-$i',
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SizedBox(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            child: InteractiveViewer(
                              minScale: 1.0,
                              maxScale: 4.0,
                              boundaryMargin: const EdgeInsets.all(0),
                              clipBehavior: Clip.none,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: constraints.maxWidth,
                                  height: constraints.maxHeight,
                                  child: imageWidget,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                splashRadius: 24,
                onPressed: () => Get.back(),
                icon: const Icon(
                  Iconsax.close_circle_copy,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          if (images.isNotEmpty)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${index + 1}/${images.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
