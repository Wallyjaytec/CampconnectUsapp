import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/back_icon_widget.dart';

class SupportView extends StatelessWidget {
  const SupportView({super.key});

  Future<void> _refresh() async {
    // Refresh storage data
  }

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    final chats = box.read<List>('support_chats') ?? [];
    final hasHistory = chats.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        leading: const BackIconWidget(),
        centerTitle: false,
        titleSpacing: 0,
        title: Text('Customer Support'.tr,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18)),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primaryColor,
        child: Column(
          children: [
            Expanded(child: _buildWelcome()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (hasHistory)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () => Get.toNamed(AppRoutes.supportHistoryView),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.primaryColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Chat History'.tr,
                                style: const TextStyle(color: AppColors.primaryColor, fontSize: 14)),
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Get.toNamed(AppRoutes.supportChatView),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('New Conversation'.tr,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    final suggestions = [
      'How do I track my order?',
      'What is the return policy?',
      'How to request a refund?',
      'How to recharge my wallet?',
      'What payment methods are available?',
      'How to close my account?',
      'How to report a seller?',
      'What shipping methods do you offer?',
    ];

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset('assets/icons/customer_support.png', width: 80, height: 80),
            ),
            const SizedBox(height: 12),
            Text('CampConnectUs Virtual Assistant',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Image.asset('assets/images/verifybadge.png', width: 16, height: 16),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              "👋 Welcome! We're here to help you with any issue you're facing. Take a deep breath, we'll sort everything out together.".tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Text('💡 ${'Frequently Asked'.tr}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: suggestions.map((s) {
                return ActionChip(
                  label: Text(s.tr, style: const TextStyle(fontSize: 11)),
                  onPressed: () {
                    Get.toNamed(AppRoutes.supportChatView, arguments: [
                      {'role': 'user', 'text': s, 'time': DateTime.now().toIso8601String()}
                    ]);
                  },
                  backgroundColor: AppColors.primaryColor.withValues(alpha: 0.08),
                  side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap below to start a new conversation with our virtual assistant.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
