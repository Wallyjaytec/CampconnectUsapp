import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class BannerCarousel extends StatefulWidget {
  final List<Widget> items;
  final double height;
  final double viewportFraction;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;

  final bool padEnds;
  final double itemSpacing;

  const BannerCarousel({
    super.key,
    required this.items,
    this.height = 130,
    this.viewportFraction = 0.95,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.padding,
    this.padEnds = false,
    this.itemSpacing = 8,
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final RxInt _index = 0.obs;
  final CarouselSliderControllerImpl _controller =
      CarouselSliderControllerImpl();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dotInactive = (isDark ? Colors.white : Colors.black).withValues(
      alpha: .25,
    );
    final dotActive = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: widget.height,
            child: CarouselSlider.builder(
              carouselController: _controller,
              itemCount: widget.items.length,
              itemBuilder: (context, i, _) {
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.itemSpacing / 2,
                  ),
                  child: ClipRRect(
                    borderRadius: widget.borderRadius,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(onTap: () {}, child: widget.items[i]),
                    ),
                  ),
                );
              },
              options: CarouselOptions(
                height: widget.height,
                viewportFraction: widget.viewportFraction,
                padEnds: widget.padEnds,
                enlargeCenterPage: false,
                enableInfiniteScroll: widget.items.length > 1,
                autoPlay: widget.autoPlay && widget.items.length > 1,
                autoPlayInterval: widget.autoPlayInterval,
                onPageChanged: (i, _) => _index.value = i,
                clipBehavior: Clip.none,
              ),
            ),
          ),
          if (widget.items.length > 1) ...[
            const SizedBox(height: 10),
            Obx(
              () => AnimatedSmoothIndicator(
                activeIndex: _index.value,
                count: widget.items.length,
                onDotClicked: (i) => _controller.animateToPage(i),
                effect: ExpandingDotsEffect(
                  expansionFactor: 3,
                  dotHeight: 8,
                  dotWidth: 8,
                  spacing: 6,
                  dotColor: dotInactive,
                  activeDotColor: dotActive,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
