import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kartly_e_commerce/core/services/api_service.dart';
import 'package:kartly_e_commerce/data/repositories/compare_repository.dart';
import 'package:kartly_e_commerce/data/repositories/product_details_repository.dart';
import 'package:kartly_e_commerce/modules/product/view/related_product_view.dart';
import 'package:kartly_e_commerce/modules/seller/controller/seller_products_controller.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'package:kartly_e_commerce/shared/utils/dialog_utils.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/guest_cart_service.dart';
import '../../../core/services/login_service.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/youtube_utils.dart';
import '../../../data/repositories/cart_repository.dart';
import '../../../shared/widgets/back_icon_widget.dart';
import '../../../shared/widgets/cart_icon_widget.dart';
import '../../../shared/widgets/notification_icon_widget.dart';
import '../../../shared/widgets/search_icon_widget.dart';
import '../../compare/controller/compare_controller.dart';
import '../../seller/model/seller_shop_model.dart';
import '../../wishlist/controller/wishlist_controller.dart';
import '../controller/cart_controller.dart';
import '../controller/description_controller.dart';
import '../controller/product_details_controller.dart';
import '../model/cart_item_model.dart';
import '../model/product_details_model.dart';
import '../model/product_model.dart';
import '../model/review_model.dart';
import '../widgets/star_row.dart';

class ProductDetailsView extends StatelessWidget {
  ProductDetailsView({super.key}) {
    // Force controller registration early
    final args = Get.arguments;
    final permalink = (args is Map) ? (args['permalink'] ?? args['slug'] ?? '') : '';
    final tag = 'product_$permalink';
    if (!Get.isRegistered<ProductDetailsController>(tag: tag)) {
      Get.put(
        ProductDetailsController(ProductDetailsRepository(ApiService()), permalink: permalink),
        tag: tag,
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
  child: Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 44,
          leading: const BackIconWidget(),
          centerTitle: false,
          titleSpacing: 0,
          title: Obx(() {
            final p = controller.product.value;
            return Text(
              p?.name ?? 'Product Details'.tr,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 18,
              ),
            );
          }),
          actionsPadding: const EdgeInsetsDirectional.only(end: 10),
          actions: const [
            SearchIconWidget(),
            CartIconWidget(),
            NotificationIconWidget(),
          ],
        ),
        bottomNavigationBar: _BottomBar(),
        body: Obx(() {
          if (controller.isLoading.value && controller.product.value == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.error.isNotEmpty && controller.product.value == null) {
            return _ErrorPane(
              message: controller.error.value,
              onRetry: controller.load,
            );
          }
          final p = controller.product.value!;

          return RefreshIndicator(
            onRefresh: controller.load,
            child: ListView(
              children: [
                _Gallery(p: p),
                const SizedBox(height: 12),
                const _OverviewBlock(),
                const SizedBox(height: 12),
                if (controller.hasVariationsProduct) ...[
                  const _VariationBlock(),
                  const SizedBox(height: 12),
                ],
                _InfoPanel(p: p),
                const SizedBox(height: 12),
                const _ReviewsSection(),
                const SizedBox(height: 12),
                _ShopCard(p: p),
                const SizedBox(height: 12),
                _Description(p: p),
                const SizedBox(height: 12),
                const RelatedProductView(),
                const SizedBox(height: 12),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _VariationBlock extends StatelessWidget {
  const _VariationBlock();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: GestureDetector(
            onTap: () {
              final c = Get.find<ProductDetailsController>();
              c.openAddToCartSheet();
            },
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardColor
                    : AppColors.lightCardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  spacing: 10,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      spacing: 10,
                      children: [
                        const Icon(
                          Iconsax.category_2,
                          size: 18,
                          color: AppColors.primaryColor,
                        ),
                        Text(
                          'Select Variation'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const Icon(Iconsax.arrow_right_3_copy, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorPane extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorPane({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: Text('Retry'.tr)),
          ],
        ),
      ),
    );
  }
}


class _Gallery extends StatelessWidget {
  const _Gallery({required this.p});
  final ProductDetailsModel p;

  @override
  Widget build(BuildContext context) {
    // ✅ CHANGE 2: Use Get.find() instead of Get.put()
    final controller = Get.find<ProductDetailsController>();
    final height = MediaQuery.sizeOf(context).width;

    final wish = WishlistController.ensure();

    final media = <MediaItem>[];
    for (final item in p.galleryImages) {
      if (item.isVideo) {
        final link = (item.videoLink ?? '').trim();
        if (link.isNotEmpty && isYouTubeUrl(link)) {
          final id = extractYouTubeId(link);
          if (id != null) {
            final thumb = (item.videoThumb.isNotEmpty)
                ? item.videoThumb
                : youtubeThumb(id);
            media.add(MediaItem.youtube(url: link, videoId: id, thumb: thumb));
          }
        }
      } else {
        final img = item.imageUrl;
        if (img.isNotEmpty) {
          media.add(MediaItem.image(img));
        }
      }
    }

    final String primaryImage = (() {
      try {
        return media.firstWhere((m) => !m.isVideo).url;
      } catch (_) {
        try {
          return media.firstWhere((m) => m.isVideo).thumb ?? '';
        } catch (_) {
          return '';
        }
      }
    })();

    ProductModel toPm() {
      final double price = p.price;
      final double rating = p.rating;
      return ProductModel(
        id: p.id,
        title: (p.name).toString(),
        slug: p.permalink,
        image: primaryImage,
        price: price,
        oldPrice: null,
        rating: rating,
        currency: '',
        totalReviews: 0,
        hasVariant: false,
        quantity: 0,
        unit: '',
      );
    }

    final compareCtrl = Get.isRegistered<CompareController>()
        ? Get.find<CompareController>()
        : Get.put(
            CompareController(CompareRepository(ApiService()), ApiService()),
            permanent: true,
          );

    return Container(
      color: AppColors.lightBackgroundColor,
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          if (media.isEmpty)
            Container(
              height: height,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
              child: const Center(child: Icon(Icons.broken_image_outlined)),
            )
          else
            CarouselSlider.builder(
              itemCount: media.length,
              itemBuilder: (context, i, _) {
                final item = media[i];
                if (!item.isVideo) {
                  return GestureDetector(
                    onTap: () {
                      final imageOnly = media
                          .where((m) => !m.isVideo)
                          .map((m) => m.url)
                          .toList();
                      final tapped = imageOnly.indexOf(item.url);
                      Get.toNamed(
                        AppRoutes.fullScreenImageView,
                        arguments: {
                          'images': imageOnly,
                          'index': tapped < 0 ? 0 : tapped,
                          'id': controller.product.value?.id,
                          'heroPrefix': 'product',
                        },
                      );
                    },
                    child: _ImageAuto(item.url),
                  );
                }
                final thumb = item.thumb ?? youtubeThumb(item.videoId!);
                return GestureDetector(
                  onTap: () => Get.to(
                    () => FullscreenYouTubeView(videoId: item.videoId!),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ImageAuto(thumb),
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              options: CarouselOptions(
                height: height,
                viewportFraction: 1,
                enlargeCenterPage: false,
                autoPlay: media.length > 1,
                autoPlayInterval: const Duration(seconds: 4),
                enableInfiniteScroll: media.length > 1,
                onPageChanged: (i, _) => controller.onPageChanged(i),
              ),
            ),

          if (media.length > 1)
            Positioned(
              bottom: 12,
              child: Obx(
                () => AnimatedSmoothIndicator(
                  activeIndex: controller.galleryIndex.value,
                  count: media.length,
                  effect: const ExpandingDotsEffect(
                    expansionFactor: 3,
                    dotHeight: 8,
                    dotWidth: 8,
                    spacing: 6,
                    dotColor: Color(0x33000000),
                    activeDotColor: AppColors.primaryColor,
                  ),
                ),
              ),
            ),

          Positioned(
            top: 10,
            right: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() {
                  final pid = p.id;
                  final isIn = (pid > 0) ? wish.isInWishlist(pid) : false;
                  return _CircleIconButton(
                    icon: isIn ? Iconsax.heart : Iconsax.heart_copy,
                    color: isIn ? AppColors.favColor : AppColors.whiteColor,
                    onTap: () {
                      if (pid <= 0) return;
                      wish.toggle(toPm());
                    },
                  );
                }),
                const SizedBox(height: 8),
                Obx(() {
                  final isInCompare = compareCtrl.isInCompare(p.id);
                  final count = compareCtrl.compareCount;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _CircleIconButton(
                        icon: Iconsax.arrow_swap_horizontal_copy,
                        color: isInCompare ? Colors.black : AppColors.whiteColor,
                        onTap: () async {
                          if (isInCompare) {
                            compareCtrl.removeFromCompareById(p.id);
                          } else {
                            await compareCtrl.addToCompareByIds([p.id]);
                            Get.snackbar(
                              'Compare'.tr,
                              '${p.name} ${'added to compare'.tr}',
                              snackPosition: SnackPosition.TOP,
                              backgroundColor: AppColors.primaryColor,
                              colorText: AppColors.whiteColor,
                            );
                          }
                        },
                      ),
                      if (count > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
                const SizedBox(height: 8),
                _CircleIconButton(
                  icon: Iconsax.share,
                  color: AppColors.whiteColor,
                  onTap: () async {
                    controller.shareProduct(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
                    
class _ImageAuto extends StatelessWidget {
  const _ImageAuto(this.path);
  final String path;

  @override
  Widget build(BuildContext context) {
    final url = normalizeUrl(path);
    final isNet = url.startsWith('http://') || url.startsWith('https://');
    return isNet
        ? Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          )
        : Image.asset(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
  }
}

class FullscreenYouTubeView extends StatefulWidget {
  const FullscreenYouTubeView({super.key, required this.videoId});
  final String videoId;

  @override
  State<FullscreenYouTubeView> createState() => _FullscreenYouTubeViewState();
}

class _FullscreenYouTubeViewState extends State<FullscreenYouTubeView> {
  late final YoutubePlayerController _yt;

  @override
  void initState() {
    super.initState();
    _yt = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        playsInline: false,
        showControls: true,
      ),
    );
  }

  @override
  void dispose() {
    _yt.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => safeBack(),
        ),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: YoutubePlayerScaffold(
          controller: _yt,
          aspectRatio: 16 / 9,
          builder: (context, player) => player,
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.p});
  final ProductDetailsModel p;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = <_InfoItem>[
      _InfoItem(
        icon: Icons.verified_outlined,
        title: 'Conditions'.tr,
        subtitle: 'Product Condition'.tr,
        value: p.condition.tr,
      ),
      _InfoItem(
        icon: Icons.copyright_outlined,
        title: 'Authentic'.tr,
        subtitle: 'Authenticity'.tr,
        value: p.isAuthentic.tr,
      ),
      _InfoItem(
        icon: Icons.payments_outlined,
        title: 'Payment Option'.tr,
        subtitle: 'Cash on Delivery'.tr,
        value: p.isActiveCod.tr,
      ),
      _InfoItem(
        icon: Icons.undo_outlined,
        title: 'Return Options'.tr,
        subtitle: 'Change of mind is not applicable'.tr,
        value: p.returnOption.tr,
        valueColor: Colors.red,
      ),
      _InfoItem(
        icon: Icons.shield_outlined,
        title: 'Warranty'.tr,
        subtitle: 'Seller warranty'.tr,
        value: (p.hasWarranty || p.hasReplacementWarranty)
            ? '${p.warrantyDays} ${'days'.tr}'
            : 'Not available'.tr,
        valueColor: (p.hasWarranty || p.hasReplacementWarranty)
            ? null
            : Colors.red,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
          itemBuilder: (_, i) {
            final e = items[i];
            return ListTile(
              leading: Icon(e.icon, size: 22, color: theme.colorScheme.primary),
              title: Text(
                e.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(e.subtitle),
              trailing: e.value.isEmpty
                  ? null
                  : Text(
                      e.value,
                      style: TextStyle(
                        color: e.valueColor ?? theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              dense: true,
              visualDensity: const VisualDensity(vertical: -4),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 0,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CollapsedProbe extends StatefulWidget {
  const _CollapsedProbe({
    required this.child,
    required this.maxHeight,
    required this.onNeedsMoreChanged,
  });

  final Widget child;
  final double maxHeight;
  final ValueChanged<bool> onNeedsMoreChanged;

  @override
  State<_CollapsedProbe> createState() => _CollapsedProbeState();
}

class _CollapsedProbeState extends State<_CollapsedProbe> {
  final ScrollController _ctrl = ScrollController();
  bool _measured = false;
  bool _needsMore = false;

  void _measure() {
    if (!_ctrl.hasClients) return;
    final overflow = _ctrl.position.maxScrollExtent > 0.0;
    if (overflow != _needsMore) {
      setState(() => _needsMore = overflow);
      widget.onNeedsMoreChanged(overflow);
    } else if (!_measured) {
      widget.onNeedsMoreChanged(overflow);
    }
    _measured = true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant _CollapsedProbe oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  Widget build(BuildContext context) {
    if (_measured && !_needsMore) return widget.child;

    return SizedBox(
      height: widget.maxHeight,
      child: SingleChildScrollView(
        controller: _ctrl,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        child: widget.child,
      ),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description({required this.p});
  final ProductDetailsModel p;

  static const double _collapsedHeight = 90;
  static const double _shadeHeight = 24.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String html = _fixRelativeSrc(
      p.descriptionHtml.isEmpty
          ? '<p>No description available.</p>'
          : p.descriptionHtml,
    );

    final ctrl = Get.put(DescriptionController(), tag: 'desc_${p.id}');

    Widget buildHtml({required bool expanded}) {
      final baseColor = isDark ? '#E5E7EB' : '#222222';

      String mb(String normal) => expanded ? normal : '4px';
      return HtmlWidget(
        html,
        enableCaching: true,
        renderMode: RenderMode.column,
        buildAsync: false,
        textStyle: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: isDark ? Colors.white70 : const Color(0xFF222222),
        ),
        customWidgetBuilder: (element) {
          final tag = element.localName?.toLowerCase();
          if (tag == 'table') {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: HtmlWidget(
                element.outerHtml,
                textStyle: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: isDark ? Colors.white70 : const Color(0xFF222222),
                ),
                customWidgetBuilder: (_) => null,
                customStylesBuilder: (el) {
                  final t = el.localName?.toLowerCase();
                  switch (t) {
                    case 'table':
                      return {
                        'margin': '0 0 ${mb('10px')} 0',
                        'border-spacing': '0',
                        'border-left': '1px solid #e5e7eb',
                        'border-top': '1px solid #e5e7eb',
                        'width': '100%',
                      };
                    case 'th':
                    case 'td':
                      return {
                        'padding': '6px',
                        'border-right': '1px solid #e5e7eb',
                        'border-bottom': '1px solid #e5e7eb',
                        'border-left': '0',
                        'border-top': '0',
                        'vertical-align': 'top',
                        'color': baseColor,
                      };
                  }
                  return null;
                },
              ),
            );
          }
          return null;
        },
        customStylesBuilder: (element) {
          final tag = element.localName?.toLowerCase();
          switch (tag) {
            case 'p':
              return {
                'margin': '0 0 ${mb('10px')} 0',
                'line-height': '1.6',
                'color': baseColor,
              };
            case 'ul':
            case 'ol':
              return {
                'margin': '0 0 ${mb('10px')} 18px',
                'padding-left': '16px',
                'line-height': '1.6',
                'color': baseColor,
              };
            case 'li':
              return {
                'margin': '0 0 ${mb('6px')} 0',
                'line-height': '1.6',
                'color': baseColor,
              };
            case 'h1':
              return {
                'font-size': '20px',
                'font-weight': '700',
                'margin': '${mb('12px')} 0 ${mb('8px')} 0',
                'color': baseColor,
              };
            case 'h2':
              return {
                'font-size': '18px',
                'font-weight': '700',
                'margin': '${mb('12px')} 0 ${mb('8px')} 0',
                'color': baseColor,
              };
            case 'h3':
              return {
                'font-size': '16px',
                'font-weight': '700',
                'margin': '${mb('10px')} 0 ${mb('6px')} 0',
                'color': baseColor,
              };
            case 'span':
            case 'div':
            case 'a':
              return {'color': baseColor};
            default:
              return null;
          }
        },
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description'.tr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          Obx(() {
            final expanded = ctrl.expanded.value;

            final Widget content = expanded
                ? buildHtml(expanded: true)
                : _CollapsedProbe(
                    maxHeight: _collapsedHeight,
                    onNeedsMoreChanged: (v) => ctrl.needsMore.value = v,
                    child: buildHtml(expanded: false),
                  );

            return Stack(
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: content,
                ),
                if (!expanded && ctrl.needsMore.value)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -10,
                    child: IgnorePointer(
                      child: Container(
                        height: _shadeHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              (isDark
                                      ? AppColors.darkCardColor
                                      : AppColors.lightCardColor)
                                  .withValues(alpha: 0.0),
                              (isDark
                                  ? AppColors.darkCardColor
                                  : AppColors.lightCardColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
          Obx(() {
            if (!ctrl.expanded.value) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GestureDetector(
                  onTap: () {
                    ctrl.toggle();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'See more'.tr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () {
                  ctrl.toggle();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'See Less'.tr,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

String _fixRelativeSrc(String html) {
  final reg = RegExp(r'src="(/[^"]+)"', caseSensitive: false);
  return html.replaceAllMapped(reg, (m) {
    final rel = m.group(1) ?? '';
    return 'src="${AppConfig.assetUrl(rel)}"';
  });
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.p});
  final ProductDetailsModel p;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = p.shopInfo;

    final rawSlug = (s.slug).toString().trim();
    final slug = rawSlug.isNotEmpty ? rawSlug : _slugify(s.name);

    final seedFollowers = (() {
      final tf = s.totalFollowers;
      return tf;
    })();

    final bool alreadyFollowing = s.isFollowing;

    final tag = 'seller_header_$slug';
    final sellerCtrl = Get.isRegistered<SellerProductsController>(tag: tag)
        ? Get.find<SellerProductsController>(tag: tag)
        : Get.put(
            SellerProductsController(slug: slug, autoLoad: false),
            tag: tag,
          );

    sellerCtrl.seedHeaderMeta(
      followersCount: seedFollowers,
      alreadyFollowing: alreadyFollowing,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkCardColor
              : AppColors.lightCardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final s = p.shopInfo;

                      String slug = '';
                      final rawSlug = (s.slug).toString().trim();
                      final rawShopSlug = (s.slug).toString().trim();

                      if (rawSlug.isNotEmpty) {
                        slug = rawSlug;
                      } else if (rawShopSlug.isNotEmpty) {
                        slug = rawShopSlug;
                      } else {
                        slug = s.name
                            .toLowerCase()
                            .trim()
                            .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                            .replaceAll(RegExp(r'-+'), '-')
                            .replaceAll(RegExp(r'^-|-$'), '');
                      }

                      int ratingPercent = 0;
                      final pr = (s.positiveRating).toString();
                      ratingPercent = int.tryParse(pr) ?? 0;

                      int followers = 0;
                      final tf = s.totalFollowers;
                      followers = tf;

                      Get.toNamed(
                        AppRoutes.sellerBottomNavbar,
                        arguments: SellerNavArgs(
                          title: s.name,
                          logo: s.logo,
                          slug: slug,
                          ratingPercent: ratingPercent,
                          followers: sellerCtrl.followers.value,
                          shopBanner: s.shopBanner,
                          isFollowing: s.isFollowing,
                          isVerified: s.isVerified,
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: s.logo,
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.store_mall_directory_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            final s = p.shopInfo;

                            String slug = '';
                            final rawSlug = (s.slug).toString().trim();
                            final rawShopSlug = (s.slug).toString().trim();

                            if (rawSlug.isNotEmpty) {
                              slug = rawSlug;
                            } else if (rawShopSlug.isNotEmpty) {
                              slug = rawShopSlug;
                            } else {
                              slug = s.name
                                  .toLowerCase()
                                  .trim()
                                  .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                                  .replaceAll(RegExp(r'-+'), '-')
                                  .replaceAll(RegExp(r'^-|-$'), '');
                            }

                            int ratingPercent = 0;
                            final pr = (s.positiveRating).toString();
                            ratingPercent = int.tryParse(pr) ?? 0;

                            int followers = 0;
                            final tf = s.totalFollowers;
                            followers = tf;

                            Get.toNamed(
                              AppRoutes.sellerBottomNavbar,
                              arguments: SellerNavArgs(
                                title: s.name,
                                logo: s.logo,
                                slug: slug,
                                ratingPercent: ratingPercent,
                                followers: sellerCtrl.followers.value,
                                shopBanner: s.shopBanner,
                                isFollowing: s.isFollowing,
                                isVerified: s.isVerified,
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  s.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (s.isVerified) ...[
                                const SizedBox(width: 4),
                                Image.asset('assets/images/verifybadge.png', height: 18, width: 18),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: Colors.amber[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              s.avgRating.toStringAsFixed(1),
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                 Obx(() {
  final following = sellerCtrl.isFollowing.value;
  final busy = sellerCtrl.followBusy;

  return TextButton(
    onPressed: busy
        ? null
        : following
            ? () => sellerCtrl.unfollowShop()
            : () => sellerCtrl.followShop(),
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      backgroundColor: following
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : AppColors.primaryColor,
      foregroundColor: following
          ? Theme.of(context).colorScheme.onSurface
          : AppColors.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    child: Text(following ? 'Following'.tr : 'Follow'.tr),
  );
}), 
                ],
              ),
            ),

            Divider(
              height: 1,
              color: theme.dividerColor.withValues(alpha: 0.2),
            ),
            Padding(
  padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8, top: 8),
  child: IntrinsicHeight(
    child: Row(
      children: [
        Expanded(child: _ShopStat(label: 'Positive feedback'.tr, value: '${s.positiveRating}%')),
        VerticalDivider(width: 12, thickness: 1, color: theme.dividerColor.withValues(alpha: 0.25)),
        Expanded(child: _ShopStat(label: 'Products'.tr, value: '${s.totalProduct}')),
        VerticalDivider(width: 12, thickness: 1, color: theme.dividerColor.withValues(alpha: 0.25)),
        Expanded(child: Obx(() => _ShopStat(label: 'Followers'.tr, value: '${sellerCtrl.followers.value}'))),
        VerticalDivider(width: 12, thickness: 1, color: theme.dividerColor.withValues(alpha: 0.25)),
        Expanded(child: _ShopStat(label: 'Verified'.tr, value: s.isVerified ? '100%' : '0%')),
      ],
    ),
  ),
),
          ],
        ),
      ),
    );
  }
}

String _slugify(String input) => input
    .toLowerCase()
    .trim()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'-+'), '-')
    .replaceAll(RegExp(r'^-|-$'), '');


class _ShopStat extends StatelessWidget {
  final String label;
  final String value;
  const _ShopStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis, maxLines: 1),
      ],
    );
  }
}
class _InfoItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final Color? valueColor;
  const _InfoItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.valueColor,
  });
}

class _BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Get.find<ProductDetailsController>();

    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          boxShadow: const [
            BoxShadow(
              blurRadius: 12,
              offset: Offset(0, -4),
              color: Color(0x1A000000),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: _MiniAction(
                icon: Obx(() {
                  final logo = controller.product.value?.shopInfo.logo ?? '';
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: logo,
                      width: 26,
                      height: 26,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.store_mall_directory_outlined),
                    ),
                  );
                }),
                label: 'Store'.tr,
                onTap: () {
                  final p = controller.product.value;
                  if (p == null) return;

                  final s = p.shopInfo;

                  String slug = '';
                  final rawSlug = (s.slug).toString().trim();

                  if (rawSlug.isNotEmpty) {
                    slug = rawSlug;
                  } else {
                    slug = s.name
                        .toLowerCase()
                        .trim()
                        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                        .replaceAll(RegExp(r'-+'), '-')
                        .replaceAll(RegExp(r'^-|-$'), '');
                  }

                  final int ratingPercent =
                      int.tryParse((s.positiveRating).toString()) ?? 0;

                  final tag2 = 'seller_bottom_$slug';
                  final sellerCtrl2 = Get.isRegistered<SellerProductsController>(tag: tag2)
                      ? Get.find<SellerProductsController>(tag: tag2)
                      : Get.put(
                          SellerProductsController(slug: slug, autoLoad: false),
                          tag: tag2,
                        );
                  sellerCtrl2.seedHeaderMeta(
                    followersCount: s.totalFollowers,
                    alreadyFollowing: s.isFollowing,
                  );

                  Get.toNamed(
                    AppRoutes.sellerBottomNavbar,
                    arguments: SellerNavArgs(
                      title: s.name,
                      logo: s.logo,
                      slug: slug,
                      ratingPercent: ratingPercent,
                      followers: sellerCtrl2.followers.value,
                      shopBanner: s.shopBanner,
                      isFollowing: s.isFollowing,
                      isVerified: s.isVerified,
                    ),
                  );
                },
              ),
            ),
            Expanded(
              flex: 2,
              child: Obx(() {
                final isLoading = controller.isLoading.value;
                final isBuying = controller.buyNowLoading.value;
                final p = controller.product.value;
                final outOfStock = p != null && p.quantity <= 0;
                final disabled = isLoading || outOfStock || isBuying;
                return SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: disabled
                          ? AppColors.lightBlueColor.withValues(alpha: 0.5)
                          : AppColors.lightBlueColor,
                    ),
                    onPressed: disabled
                        ? null
                        : () {
                            final c = Get.find<ProductDetailsController>();
                            _handleBuyNow(c);
                          },
                    child: Center(
                      child: isBuying
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(
                              outOfStock ? 'Out of Stock'.tr : 'Buy Now'.tr,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              softWrap: false,
                            ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Obx(() {
                final isLoading = controller.isLoading.value;
                return SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLoading
                          ? AppColors.primaryColor.withValues(alpha: 0.5)
                          : AppColors.primaryColor,
                    ),
                    onPressed: isLoading
                        ? null
                        : () {
                            final c = Get.find<ProductDetailsController>();
                            c.openAddToCartSheet();
                          },
                    child: Center(
                      child: Text(
                        'Add To Cart'.tr,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : const Color(0xFF444444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _BigCTA extends StatelessWidget {
  const _BigCTA({
    required this.text,
    required this.background,
    required this.onTap,
  });
  final String text;
  final Color background;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: background),
        onPressed: onTap,
        child: Center(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ),
    );
  }
}

class _OverviewBlock extends StatelessWidget {
  const _OverviewBlock();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // ✅ CHANGE 4: Use Get.find() instead of Get.put()
    final controller = Get.find<ProductDetailsController>();

    return Obx(() {
      final p = controller.product.value;
      if (p == null) return const SizedBox.shrink();

      final bool hasRange =
          (p.priceRangeMin != null &&
          p.priceRangeMax != null &&
          p.priceRangeMax! >= (p.priceRangeMin ?? 0));

      final bool hasOldRange =
          (p.priceRangeMinOld != null &&
          p.priceRangeMaxOld != null &&
          p.priceRangeMaxOld! >= (p.priceRangeMinOld ?? 0));

      final double singlePrice = controller.effectivePrice;
      final double? singleOld = controller.effectiveOldPrice;

      final double? old = controller.effectiveOldPrice;

      String? oldText = (old != null)
          ? formatCurrencyCompact(old, applyConversion: true)
          : null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardColor
                    : AppColors.lightCardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 8,
                  bottom: 6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _FiveStarRow(rating: p.rating),
                        const SizedBox(width: 8),
                        Text(
                          '${p.rating.toStringAsFixed(1)} (${formatCount(p.totalReviews)})',
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (hasRange) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${formatCurrency(p.priceRangeMin ?? p.price, applyConversion: true)} – '
                            '${formatCurrency(p.priceRangeMax ?? p.price, applyConversion: true)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              height: 1.6,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          if (hasOldRange) ...[
                            Text(
                              '${formatCurrency(p.priceRangeMinOld!, applyConversion: true)} – '
                              '${formatCurrency(p.priceRangeMaxOld!, applyConversion: true)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.greyColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              formatCurrency(
                                singlePrice,
                                applyConversion: true,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                          if (oldText != null) ...[
                            const SizedBox(width: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                formatCurrency(
                                  singleOld,
                                  applyConversion: true,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.greyColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _FiveStarRow extends StatelessWidget {
  const _FiveStarRow({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    final double r = rating.clamp(0.0, 5.0);
    final int full = r.floor();
    final bool hasHalf = (r - full) >= 0.25 && (r - full) < 0.75;
    final int half = hasHalf ? 1 : 0;
    final int empty = 5 - full - half;

    List<Widget> icons = [];
    for (int i = 0; i < full; i++) {
      icons.add(
        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFC107)),
      );
    }
    if (half == 1) {
      icons.add(
        const Icon(Icons.star_half_rounded, size: 16, color: Color(0xFFFFC107)),
      );
    }
    for (int i = 0; i < empty; i++) {
      icons.add(
        Icon(Icons.star_border_rounded, size: 16, color: Colors.amber[700]),
      );
    }

    return Row(children: icons);
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // ✅ CHANGE 5: Use Get.find() instead of Get.put()
    final controller = Get.find<ProductDetailsController>();

    return Obx(() {
      final totalText = controller.totalReviewsText;
      final list = controller.recentReviews;
      final total = controller.reviewsTotal.value;

      return Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 8,
                  bottom: 0,
                ),
                child: Row(
                  children: [
                    Text(
                      'Reviews'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('($totalText)', style: theme.textTheme.labelMedium),
                    const Spacer(),
                    Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (controller.product.value?.rating ?? 0).toStringAsFixed(
                        1,
                      ),
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (controller.isLoadingRecent.value)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'No reviews yet'.tr,
                    style: theme.textTheme.bodySmall,
                  ),
                )
              else
                ListView.separated(
                  itemCount: list.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final item = list[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      child: _ReviewTileApi(item: item),
                    );
                  },
                ),

              if (total > 0) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: controller.openAllReviews,
                    child: Text('See all reviews'.tr),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _ReviewTileApi extends StatelessWidget {
  const _ReviewTileApi({required this.item});
  final ProductReview item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeText = item.time != null
        ? DateFormat('d MMM yyyy hh:mm:ss a').format(item.time!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: (item.customer.avatarUrl.isNotEmpty)
                  ? CachedNetworkImageProvider(item.customer.avatarUrl)
                  : null,
              child: item.customer.avatarUrl.isEmpty
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.customer.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.customer.verified == 1 ||
                          item.customer.verified == 2)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  StarRow(rating: item.rating),
                  if (timeText != null) ...[
                    const SizedBox(height: 6),
                    Text(timeText, style: theme.textTheme.labelSmall),
                  ],
                ],
              ),
            ),
          ],
        ),

        if (item.review.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(item.review),
        ],

        if (item.images.isNotEmpty) ...[
          const SizedBox(height: 10),
          _ReviewImagesStrip(images: item.images),
        ],
      ],
    );
  }
}

class _ReviewImagesStrip extends StatelessWidget {
  const _ReviewImagesStrip({required this.images});
  final List<String> images;

  @override
  Widget build(BuildContext context) {
    const double h = 76;
    const double w = 76;

    return SizedBox(
      height: h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: images.length,
        itemBuilder: (_, i) {
          final src = images[i];
          return GestureDetector(
            onTap: () {
              Get.toNamed(
                AppRoutes.fullScreenImageView,
                arguments: {
                  'images': images,
                  'index': i,
                  'title':
                      (Get.find<ProductDetailsController>()
                          .product
                          .value
                          ?.name) ??
                      'Gallery',
                },
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: src,
                width: w,
                height: h,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: w,
                  height: h,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.06),
                  child: const Icon(Iconsax.gallery_remove_copy, size: 20),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Future<void> _handleBuyNow(ProductDetailsController controller) async {
  final p = controller.product.value;
  if (p == null || controller.buyNowLoading.value) return;

  final hasAttachmentTitle = (p.attachmentTitle ?? '').trim().isNotEmpty;

  if (controller.hasVariationsProduct || hasAttachmentTitle) {
    controller.openAddToCartSheet();
    return;
  }

  controller.buyNowLoading.value = true;

  try {
    final loggedIn = LoginService().isLoggedIn();
    final cartRepo = Get.find<CartRepository>();
    final guest = GuestCartService();

    final double unitPrice = controller.effectivePrice;
    final double oldPrice = controller.effectiveOldPrice ?? unitPrice;

    final shop = p.shopInfo;
    final image = _primaryImageFromDetails(p);

    CartListItem? existingLine;
    if (Get.isRegistered<CartController>()) {
      final cc = Get.find<CartController>();
      for (final e in cc.items) {
        if (e.id == p.id && (e.variantCode ?? '').isEmpty) {
          existingLine = e;
          break;
        }
      }
    }

    const int qty = 1;

    if (loggedIn) {
      if (existingLine != null) {
        final mergedQty = (existingLine.quantity + qty).clamp(
          1,
          existingLine.maxItem,
        );

        final updItem = CartApiItem(
          uid: existingLine.uid,
          id: p.id,
          name: (p.name).toString(),
          permalink: (p.permalink).toString(),
          image: image,
          variant: null,
          variantCode: null,
          quantity: mergedQty,
          unitPrice: unitPrice,
          oldPrice: oldPrice,
          minItem: existingLine.minItem,
          maxItem: existingLine.maxItem,
          attachment: null,
          seller: shop.id,
          shopName: shop.name,
          shopSlug: shop.slug,
          isAvailable: 1,
          isSelected: true,
        );

        await cartRepo.updateCartItem(updItem);

        if (Get.isRegistered<CartController>()) {
          final cc = Get.find<CartController>();
          await cc.refreshFromServer(prioritizeUid: existingLine.uid);
        }
      } else {
        final uid = DateTime.now().millisecondsSinceEpoch.toString();
        const int maxItem = 99;

        final newItem = CartApiItem(
          uid: uid,
          id: p.id,
          name: (p.name).toString(),
          permalink: (p.permalink).toString(),
          image: image,
          variant: null,
          variantCode: null,
          quantity: qty,
          unitPrice: unitPrice,
          oldPrice: oldPrice,
          minItem: 1,
          maxItem: maxItem,
          attachment: null,
          seller: shop.id,
          shopName: shop.name,
          shopSlug: shop.slug,
          isAvailable: 1,
          isSelected: true,
        );

        await cartRepo.storeCartItem(newItem);

        if (Get.isRegistered<CartController>()) {
          final cc = Get.find<CartController>();
          await cc.refreshFromServer(prioritizeUid: uid);
        }
      }
    } else {
      final payload = CartApiItem(
        uid: '',
        id: p.id,
        name: (p.name).toString(),
        permalink: (p.permalink).toString(),
        image: image,
        variant: null,
        variantCode: null,
        quantity: qty,
        unitPrice: unitPrice,
        oldPrice: oldPrice,
        minItem: 1,
        maxItem: 99,
        attachment: null,
        seller: shop.id,
        shopName: shop.name,
        shopSlug: shop.slug,
        isAvailable: 1,
        isSelected: true,
      );

      final uid = guest.addOrMerge(payload);

      if (Get.isRegistered<CartController>()) {
        final cc = Get.find<CartController>();
        await cc.refreshFromServer(prioritizeUid: uid);
      }
    }

    Get.toNamed(AppRoutes.cartView);
  } catch (e) {
    Get.snackbar(
      'Buy Now'.tr,
      'Failed to add item to cart'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primaryColor,
      colorText: Colors.white,
    );
  } finally {
    controller.buyNowLoading.value = false;
  }
}

String _primaryImageFromDetails(ProductDetailsModel d) {
  for (final g in d.galleryImages) {
    if (!g.isVideo && g.imageUrl.isNotEmpty) {
      return AppConfig.assetUrl(g.imageUrl);
    }
  }

  try {
    final dyn = d as dynamic;
    final primary = (dyn.thumbnail ?? dyn.image ?? '').toString();
    if (primary.isNotEmpty) return AppConfig.assetUrl(primary);
  } catch (_) {}

  return '';
}
