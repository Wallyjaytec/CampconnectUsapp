import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/back_icon_widget.dart';

class SupportHistoryView extends StatelessWidget {
  const SupportHistoryView({super.key});

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

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        leading: const BackIconWidget(),
        centerTitle: false,
        titleSpacing: 0,
        title: Text('Chat History'.tr,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18)),
      ),
      body: chats.isEmpty
          ? Center(
              child: Text('No chat history yet.'.tr,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: chats.reversed.map((chat) {
                final lastMsg = chat['last_message'] ?? '';
                final time = chat['time'] != null ? _formatTime(DateTime.parse(chat['time'])) : '';

                return InkWell(
                  onTap: () {
                    final messages = (chat['messages'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                    final chatId = chat['id']?.toString();
                    final startTime = chat['chat_start'] != null ? DateTime.parse(chat['chat_start']) : null;
                    Get.toNamed(AppRoutes.supportChatView, arguments: {
                      'messages': messages,
                      'chatId': chatId,
                      'chatStartTime': startTime?.toIso8601String(),
                    });
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
                          child: Image.asset('assets/icons/customer_support.png', width: 40, height: 40),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Flexible(
                                    child: Text('CampConnectUs Virtual Assistant',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(width: 4),
                                  Image.asset('assets/images/verifybadge.png', width: 14, height: 14),
                                  const Spacer(),
                                  Text(time, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(lastMsg.toString(), maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
