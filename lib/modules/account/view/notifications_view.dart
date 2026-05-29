import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:kartly_e_commerce/modules/account/controller/notifications_controller.dart';
import 'package:kartly_e_commerce/shared/widgets/back_icon_widget.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController());

    // Check for push notification deep link
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = GetStorage();
      final pushId = box.read<String>('push_notification_id') ?? '';
      if (pushId.isNotEmpty) {
        box.remove('push_notification_id');
        Future.delayed(const Duration(milliseconds: 500), () {
          final item = controller.items.firstWhereOrNull((e) => e.id == pushId);
          if (item != null) {
            controller.onTapNotification(item);
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        leading: Obx(() {
          if (controller.isSelectionMode.value) {
            return IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: controller.exitSelectionMode,
            );
          }
          return const BackIconWidget();
        }),
        centerTitle: false,
        titleSpacing: 0,
        title: Obx(() {
          if (controller.isSelectionMode.value) {
            return Text('${'Selected'.tr}: ${controller.selectedCount.value}');
          }
          return Text('Notification'.tr);
        }),
        actions: [
          Obx(() {
            if (controller.isSelectionMode.value) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.select_all, color: Colors.white),
                    onPressed: controller.selectAll,
                    tooltip: 'Select all'.tr,
                  ),
                  IconButton(
                    icon: const Icon(Icons.done_all, color: Colors.green),
                    onPressed: controller.markSelectedAsRead,
                    tooltip: 'Mark as read'.tr,
                  ),
                  IconButton(
                    icon: const Icon(Icons.mark_chat_unread, color: Colors.white),
                    onPressed: controller.markSelectedAsUnread,
                    tooltip: 'Mark as unread'.tr,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: controller.deleteSelected,
                    tooltip: 'Delete'.tr,
                  ),
                ],
              );
            }
            return IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: controller.showTopMenu,
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const _ShimmerList();

        if (controller.errorText.value != null) {
          return _ErrorState(
            message: controller.errorText.value!,
            onRetry: controller.load,
          );
        }

        if (controller.items.isEmpty) return const _EmptyState();

        return RefreshIndicator(
          onRefresh: controller.refreshList,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: controller.items.length,
            separatorBuilder: (_, __) => const Divider(height: 0, indent: 72, endIndent: 16),
            itemBuilder: (context, index) {
              final item = controller.items[index];
              return _NotificationTile(
                item: item,
                isSelectionMode: controller.isSelectionMode.value,
                onTap: () {
                  if (controller.isSelectionMode.value) {
                    controller.toggleSelection(item);
                  } else {
                    controller.onTapNotification(item);
                  }
                },
                onOptionsTap: () => controller.showNotificationOptions(item),
              );
            },
          ),
        );
      }),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.isSelectionMode,
    required this.onTap,
    required this.onOptionsTap,
  });
  final dynamic item;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onOptionsTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: isSelectionMode
          ? SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: item.isSelected,
                onChanged: (_) => onTap(),
                activeColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            )
          : Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.isRead ? AppColors.primaryColor.withValues(alpha: 0.5) : AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.notification_bing_copy,
                size: 18,
                color: Colors.white,
              ),
            ),
      title: Text(
        htmlToPlainText(item.message),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          item.time,
          style: const TextStyle(color: AppColors.greyColor, fontSize: 12),
        ),
      ),
      trailing: isSelectionMode
          ? null
          : Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.more_vert, size: 16, color: AppColors.primaryColor),
                onPressed: onOptionsTap,
                padding: EdgeInsets.zero,
                splashRadius: 16,
              ),
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        if (Get.isRegistered<NotificationController>()) {
          await Get.find<NotificationController>().refreshList();
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.primaryColor),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text('Failed to load notifications'.tr, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text('Retry'.tr)),
          ],
        ),
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Row(
            children: [
              Container(height: 40, width: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 12, width: double.infinity, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(width: 120, height: 10, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String htmlToPlainText(String htmlString) {
  final doc = html_parser.parse(htmlString);
  return doc.body?.text ?? '';
}
