import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/back_icon_widget.dart';

class SupportView extends StatelessWidget {
  const SupportView({super.key});

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return DateFormat('h:mm a').format(dt);
    }
    if (diff.inDays == 1) return 'Yesterday'.tr;
    if (diff.inDays < 7) return '${diff.inDays} ${'days ago'.tr}';
    return DateFormat('dd/MM/yyyy').format(dt);
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
            style:
                const TextStyle(fontWeight: FontWeight.normal, fontSize: 18)),
      ),
      body: Column(
        children: [
          Expanded(
            child: hasHistory ? _buildHistory(chats) : _buildWelcome(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Get.toNamed(AppRoutes.supportChatView);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('New Conversation'.tr,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset('assets/icons/customer_support.png',
                  width: 80, height: 80),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text('CampConnectUs Virtual Assistant'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 4),
                Image.asset('assets/images/verifybadge.png',
                    width: 18, height: 18),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              "👋 Welcome! We're here to help you with any issue you're facing. Take a deep breath, we'll sort everything out together."
                  .tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap below to start a new conversation with our virtual assistant.'
                  .tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory(List chats) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text('Chat History'.tr,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
          ),
        ),
        ...chats.reversed.map((chat) {
          final lastMsg = chat['last_message'] ?? '';
          final time = chat['time'] != null
              ? _formatTime(DateTime.parse(chat['time']))
              : '';

          return InkWell(
            onTap: () {
              final messages =
                  (chat['messages'] as List?)?.cast<Map<String, dynamic>>() ??
                      [];
              Get.toNamed(AppRoutes.supportChatView,
                  arguments: messages);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkCardColor
                    : AppColors.lightCardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.asset('assets/icons/customer_support.png',
                        width: 40, height: 40),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Flexible(
                              child: Text(
                                  'CampConnectUs Virtual Assistant',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 4),
                            Image.asset('assets/images/verifybadge.png',
                                width: 14, height: 14),
                            const Spacer(),
                            Text(time,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lastMsg.toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
