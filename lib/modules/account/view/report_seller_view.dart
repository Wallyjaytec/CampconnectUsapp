import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kartly_e_commerce/core/config/app_config.dart';
import 'package:kartly_e_commerce/core/constants/app_colors.dart';
import '../controller/report_seller_controller.dart';
import '../controller/report_seller_status_controller.dart';
import '../model/follow_seller_model.dart';
import '../model/report_seller_model.dart';
import '../widgets/report_seller_dialog.dart';

class ReportSellerView extends StatelessWidget {
  const ReportSellerView({super.key});

  @override
  Widget build(BuildContext context) {
    final reportController = Get.put(ReportSellerController());
    final statusController = Get.put(ReportSellerStatusController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final tabs = [
      Tab(height: 38, text: 'Report'.tr),
      Tab(height: 38, text: 'Report Status'.tr),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 44,
          leading: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Iconsax.arrow_left_2_copy, size: 20),
              splashRadius: 20,
            ),
          ),
          titleSpacing: 0,
          title: Text(
            'Report a Seller'.tr,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
          ),
          bottom: TabBar(
            padding: EdgeInsets.zero,
            indicatorColor: AppColors.whiteColor,
            labelColor: AppColors.whiteColor,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelColor: AppColors.greyColor,
            unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            tabs: tabs,
          ),
        ),
        body: TabBarView(
          children: [
            _ReportTab(controller: reportController, isDark: isDark),
            _ReportStatusTab(controller: statusController, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ─── Report Tab ──────────────────────────────────────────────────
class _ReportTab extends StatelessWidget {
  const _ReportTab({required this.controller, required this.isDark});
  final ReportSellerController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final searchCtrl = TextEditingController();
    final query = ''.obs;

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.error.isNotEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(controller.error.value, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: controller.loadSellers,
                  child: Text('Retry'.tr),
                ),
              ],
            ),
          ),
        );
      }

      final filtered = query.value.isEmpty
          ? controller.allSellers
          : controller.allSellers
              .where((s) => s.name.toLowerCase().contains(query.value.toLowerCase()))
              .toList();

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: searchCtrl,
              onChanged: (v) => query.value = v,
              decoration: InputDecoration(
                hintText: 'Search sellers...'.tr,
                prefixIcon: const Icon(Iconsax.search_normal_1_copy, size: 18),
                suffixIcon: query.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Iconsax.close_circle_copy, size: 18),
                        onPressed: () {
                          searchCtrl.clear();
                          query.value = '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? RefreshIndicator(
                    onRefresh: controller.loadSellers,
                    child: ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (query.value.isNotEmpty)
                                const Icon(Iconsax.search_normal_1_copy, size: 80, color: Colors.grey)
                              else
                                Image.asset('assets/icons/empty_follow.png', width: 120, height: 120),
                              const SizedBox(height: 16),
                              Text(
                                query.value.isNotEmpty ? 'No sellers found'.tr : 'No sellers available'.tr,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: controller.loadSellers,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final seller = filtered[index];
                        return _ReportSellerCard(
                          seller: seller,
                          onTap: () {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (ctx) => ReportSellerDialog(
                                sellerId: seller.id,
                                sellerName: seller.name,
                                sellerLogo: AppConfig.assetUrl(seller.logo),
                              ),
                            ).then((_) {
                              // Refresh status tab after submitting report
                              final statusCtrl = Get.find<ReportSellerStatusController>();
                              statusCtrl.loadReports();
                            });
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      );
    });
  }
}

// ─── Report Status Tab ───────────────────────────────────────────
class _ReportStatusTab extends StatelessWidget {
  const _ReportStatusTab({required this.controller, required this.isDark});
  final ReportSellerStatusController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.error.isNotEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(controller.error.value, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: controller.loadReports,
                  child: Text('Retry'.tr),
                ),
              ],
            ),
          ),
        );
      }

      if (controller.reports.isEmpty) {
        return RefreshIndicator(
          onRefresh: controller.loadReports,
          child: ListView(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.warning_2, size: 80, color: AppColors.primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'No reports submitted yet'.tr,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.loadReports,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: controller.reports.length,
          itemBuilder: (context, index) {
            final report = controller.reports[index];
            return _ReportStatusCard(report: report, isDark: isDark);
          },
        ),
      );
    });
  }
}

// ─── Report Seller Card ──────────────────────────────────────────
class _ReportSellerCard extends StatelessWidget {
  const _ReportSellerCard({required this.seller, required this.onTap});
  final FollowSellerModel seller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: AppConfig.assetUrl(seller.logo),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 56,
                height: 56,
                color: Colors.grey.shade300,
                child: const Icon(Icons.store, size: 28, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        seller.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    if (seller.isVerified) ...[
                      const SizedBox(width: 4),
                      Image.asset('assets/images/verifybadge.png', height: 16, width: 16),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${seller.positiveRating}% Seller Ratings',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${seller.followersText}  •  Verified: ${seller.isVerified ? "Yes" : "No"}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              foregroundColor: AppColors.redColor,
              side: const BorderSide(color: AppColors.redColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: Text('Report'.tr, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ─── Report Status Card ──────────────────────────────────────────
class _ReportStatusCard extends StatelessWidget {
  const _ReportStatusCard({required this.report, required this.isDark});
  final ReportSellerModel report;
  final bool isDark;

  Color get _statusColor {
    switch (report.status) {
      case 0: return Colors.orange;
      case 1: return Colors.blue;
      case 2: return Colors.green;
      default: return Colors.grey;
    }
  }

  String get _statusIcon {
    switch (report.status) {
      case 0: return '⏳';
      case 1: return '👁️';
      case 2: return '✅';
      default: return '❓';
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = '';
    try {
      final dt = DateTime.parse(report.createdAt);
      formattedDate = DateFormat('d MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      formattedDate = report.createdAt;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.shop, size: 20, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  report.shopName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_statusIcon ${report.statusText}',
                  style: TextStyle(color: _statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${'Reason'.tr}: ${report.reason}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            '${'Status'.tr}: ${report.statusText}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 2),
          Text(
            '${'Date & Time'.tr}: $formattedDate',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          // Feedback section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: report.status == 2
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Iconsax.info_circle, size: 14, color: AppColors.primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            'Feedback from Admin'.tr,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      HtmlWidget(
                        report.feedback ?? '',
                        textStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Icon(Iconsax.info_circle, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          report.hardcodedFeedback.tr,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
