import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../shared/widgets/back_icon_widget.dart';
import '../../../shared/widgets/cart_icon_widget.dart';
import '../../../shared/widgets/notification_icon_widget.dart';
import '../../../shared/widgets/search_icon_widget.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../product/widgets/star_row.dart';
import '../../wishlist/controller/wishlist_controller.dart';
import '../controller/flash_deals_controller.dart';
import '../model/flash_deal_models.dart';
import '../model/product_model.dart';

class FlashDealsView extends StatefulWidget {
  const FlashDealsView({super.key});

  @override
  State<FlashDealsView> createState() => _FlashDealsViewState();
}

class _FlashDealsViewState extends State<FlashDealsView> {
  final ScrollController _scrollCtrl = ScrollController();
  bool _showBackToTop = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (!_showBackToTop) setState(() => _showBackToTop = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showBackToTop) setState(() => _showBackToTop = false);
    });
  }

  void _scrollToTop() {
    _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<FlashDealsController>();

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 44,
          leading: const BackIconWidget(),
          centerTitle: false,
          titleSpacing: 0,
          title: Text(
            'Flash Sales'.tr,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
          ),
          actionsPadding: const EdgeInsetsDirectional.only(end: 10),
          actions: const [
            SearchIconWidget(),
            CartIconWidget(),
            NotificationIconWidget(),
          ],
        ),
        body: Stack(
          children: [
            Obx(() {
              final deals = c.visibleDeals;
              if (deals.isEmpty) {
                return Center(child: Text('No active deals'.tr));
              }

              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: deals.length,
                itemBuilder: (_, i) {
                  final d = deals[i];
                  return _DealBlock(deal: d, controller: c);
                },
              );
            }),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: _showBackToTop ? 20 : -60,
              right: 20,
              child: AnimatedOpacity(
                opacity: _showBackToTop ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: AppColors.primaryColor,
                  onPressed: _scrollToTop,
                  child: const Icon(Iconsax.arrow_up_2_copy, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DealBlock extends StatefulWidget {
  final FlashDealsController controller;
  final FlashDealSummary deal;
  const _DealBlock({required this.deal, required this.controller});

  @override
  State<_DealBlock> createState() => _DealBlockState();
}

class _DealBlockState extends State<_DealBlock> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.loadFirstPageFor(widget.deal.id);

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - 120) {
        widget.controller.loadMoreFor(widget.deal.id);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        children: [
          if ((widget.deal.backgroundImage ?? '').isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: widget.deal.backgroundImage!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 2, right: 2, bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.deal.title.isNotEmpty ? widget.deal.title : 'Flash Sales'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                _DealCountdown(dealId: widget.deal.id, endDateStr: widget.deal.endDate),
              ],
            ),
          ),
          Obx(() {
            final list = c.productsFor(widget.deal.id);
            if (list.isEmpty) {
              return const _GridShimmer();
            }
            return GridView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(0),
              itemCount: list.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, mainAxisExtent: 240,
              ),
              itemBuilder: (_, i) {
                final p = list[i];
                return _DealGridCard(
                  productId: p.id, title: p.name, imageUrl: p.image,
                  price: p.price, basePrice: p.basePrice,
                  rating: (p.rating).toDouble(),
                  onTap: () => c.openProduct(p),
                );
              },
            );
          }),
          const SizedBox(height: 8),
          Obx(() {
            final isLoadingMore = c.isLoadingMoreFor(widget.deal.id);
            final hasMore = c.hasMoreFor(widget.deal.id);
            if (isLoadingMore && hasMore) {
              return const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: _RowShimmer());
            }
            return const SizedBox.shrink();
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DealCountdown extends StatefulWidget {
  final int dealId;
  final String endDateStr;
  const _DealCountdown({required this.dealId, required this.endDateStr});

  @override
  State<_DealCountdown> createState() => _DealCountdownState();
}

class _DealCountdownState extends State<_DealCountdown> {
  Duration remaining = Duration.zero;
  Timer? _t;
  DateTime? end;

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  void initState() {
    super.initState();
    try { end = DateTime.parse(widget.endDateStr); } catch (_) {}
    _tick();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (end == null) return;
    final diff = end!.difference(DateTime.now());
    setState(() { remaining = diff.isNegative ? Duration.zero : diff; });
    if (diff.isNegative) {
      _t?.cancel();
      Get.find<FlashDealsController>().onDealExpired(widget.dealId);
    }
  }

  @override
  void dispose() { _t?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final d = remaining;
    final theme = Theme.of(context);
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    final secs = d.inSeconds % 60;

    TextStyle big = theme.textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w800);
    TextStyle small = theme.textTheme.labelSmall!.copyWith();

    Widget block(String v, String lbl) => Column(crossAxisAlignment: CrossAxisAlignment.center, children: [Text(v, style: big), Text(lbl, style: small)]);

    return Row(children: [
      block(_two(days), 'day'.tr), const SizedBox(width: 12),
      Text(':', style: theme.textTheme.titleMedium), const SizedBox(width: 12),
      block(_two(hours), 'hour'.tr), const SizedBox(width: 12),
      Text(':', style: theme.textTheme.titleMedium), const SizedBox(width: 12),
      block(_two(mins), 'minute'.tr), const SizedBox(width: 12),
      Text(':', style: theme.textTheme.titleMedium), const SizedBox(width: 12),
      block(_two(secs), 'second'.tr),
    ]);
  }
}

class _DealGridCard extends StatelessWidget {
  final int productId;
  final String title;
  final String imageUrl;
  final double price;
  final double basePrice;
  final double? rating;
  final VoidCallback onTap;
  const _DealGridCard({required this.productId, required this.title, required this.imageUrl, required this.price, required this.basePrice, required this.onTap, this.rating});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wish = WishlistController.ensure();

    ProductModel toProductModel() {
      final double? old = (basePrice > price && basePrice > 0) ? basePrice : null;
      return ProductModel(id: productId, title: title, slug: '', image: imageUrl, price: price, oldPrice: old, rating: (rating ?? 0), currency: '', totalReviews: 0, hasVariant: false, quantity: 0, unit: '');
    }

    return Container(
      clipBehavior: Clip.antiAlias, padding: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(color: isDark ? AppColors.darkProductCardColor : AppColors.lightProductCardColor, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(blurRadius: 20, offset: Offset(0, 10), color: Color(0x146A7EC8))]),
      child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(10), onTap: onTap,
        child: Column(children: [
          Expanded(child: Stack(children: [
            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(10)), child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity)),
            Positioned(right: 4, top: 4, child: Obx(() {
              final isIn = wish.isInWishlist(productId);
              return ClipRRect(borderRadius: BorderRadius.circular(18), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: InkWell(onTap: () => wish.toggle(toProductModel()), child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AppColors.primaryColor, shape: BoxShape.circle), child: Icon(isIn ? Iconsax.heart : Iconsax.heart_copy, size: 20, color: isIn ? AppColors.favColor : AppColors.whiteColor)))));
            })),
          ])),
          const SizedBox(height: 10),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.normal, height: 1))),
          const SizedBox(height: 6), StarRow(rating: (rating ?? 0).toDouble()),
          Padding(padding: const EdgeInsets.only(left: 8, right: 8), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(formatCurrency(price, applyConversion: true), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: isDark ? AppColors.whiteColor : AppColors.primaryColor)),
            if ((basePrice > price)) ...[const SizedBox(height: 2), _CenterStrike(text: formatCurrency(basePrice, applyConversion: true), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.55), decoration: TextDecoration.none))],
          ])),
          const SizedBox(height: 6),
        ]),
      )),
    );
  }
}

class _CenterStrike extends StatelessWidget {
  const _CenterStrike({required this.text, required this.style}); final String text; final TextStyle? style;
  @override
  Widget build(BuildContext context) {
    final s = style ?? DefaultTextStyle.of(context).style; final double h = s.fontSize != null ? s.fontSize! * 0.07 : 1;
    return Stack(alignment: Alignment.center, children: [
      Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: s),
      Positioned.fill(child: Align(alignment: Alignment.center, child: Container(height: h, color: (s.color ?? Theme.of(context).colorScheme.onSurface).withValues(alpha: 0.6)))),
    ]);
  }
}

class _GridShimmer extends StatelessWidget {
  const _GridShimmer();
  @override
  Widget build(BuildContext context) {
    return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.all(0), itemCount: 8, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, mainAxisExtent: 240), itemBuilder: (_, __) {
      return Container(decoration: BoxDecoration(color: Theme.of(context).dividerColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)), child: const Column(children: [Expanded(child: ShimmerBox(borderRadius: 10)), SizedBox(height: 10), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: ShimmerBox(height: 12, borderRadius: 6)), SizedBox(height: 8), ShimmerBox(height: 12, borderRadius: 6, width: 80), SizedBox(height: 10)]));
    });
  }
}

class _RowShimmer extends StatelessWidget {
  const _RowShimmer();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 120, child: Row(children: [
      Expanded(child: Padding(padding: EdgeInsets.all(6), child: ShimmerBox(borderRadius: 10))),
      Expanded(child: Padding(padding: EdgeInsets.all(6), child: ShimmerBox(borderRadius: 10))),
    ]));
  }
}
