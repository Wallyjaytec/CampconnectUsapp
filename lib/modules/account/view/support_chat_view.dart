import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/back_icon_widget.dart';
import '../controller/customer_basic_info_controller.dart';

class SupportChatView extends StatefulWidget {
  final List<Map<String, dynamic>>? existingMessages;
  const SupportChatView({super.key, this.existingMessages});

  @override
  State<SupportChatView> createState() => _SupportChatViewState();
}

class _SupportChatViewState extends State<SupportChatView>
    with TickerProviderStateMixin {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final List<Map<String, String>> _history = [];
  final box = GetStorage();
  bool _isLoading = false;
  bool _isTyping = false;
  bool _chatEnded = false;
  DateTime? _chatStartTime;

  late AnimationController _typingAnimCtrl;
  late Animation<double> _typingAnim;
  Timer? _typingTimer;

  String get _userAvatar {
    try {
      final ctrl = Get.find<CustomerBasicInfoController>();
      if (ctrl.pickedImagePath.value.isNotEmpty) return ctrl.pickedImagePath.value;
      if (ctrl.avatarUrl.value.isNotEmpty) return ctrl.avatarUrl.value;
    } catch (_) {}
    return '';
  }

  bool get _hasUserAvatar {
    try {
      final ctrl = Get.find<CustomerBasicInfoController>();
      if (ctrl.pickedImagePath.value.isNotEmpty) return true;
      if (ctrl.avatarUrl.value.isNotEmpty) return true;
    } catch (_) {}
    return false;
  }

  @override
  void initState() {
    super.initState();
    _chatStartTime = DateTime.now();

    _typingAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _typingAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_typingAnimCtrl);

    if (widget.existingMessages != null && widget.existingMessages!.isNotEmpty) {
      _messages.addAll(widget.existingMessages!);
      for (final m in widget.existingMessages!) {
        _history.add({'role': m['role'], 'content': m['text']});
      }
    }
  }

  @override
  void dispose() {
    _typingAnimCtrl.dispose();
    _typingTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  void _startTypingAnimation() {
    _typingAnimCtrl.repeat(reverse: true);
  }

  void _stopTypingAnimation() {
    _typingAnimCtrl.stop();
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isLoading || _chatEnded) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text, 'time': DateTime.now()});
      _history.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _msgCtrl.clear();
    _scrollToBottom();

    setState(() => _isTyping = true);
    _startTypingAnimation();
    _scrollToBottom();

    try {
      final uri = Uri.parse(AppConfig.chatbotChatUrl());
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': text,
          'history': _history.sublist(0, max(0, _history.length - 1)),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _stopTypingAnimation();
            _isTyping = false;
            _messages.add({
              'role': 'bot',
              'text': data['reply'],
              'time': DateTime.now()
            });
            _history.add({'role': 'assistant', 'content': data['reply']});
            if (data['action'] == 'agent_closed') _chatEnded = true;
          });
        }
      }
    } catch (_) {
      setState(() {
        _stopTypingAnimation();
        _isTyping = false;
        _messages.add({
          'role': 'bot',
          'text': 'Sorry, something went wrong. Please try again.'.tr,
          'time': DateTime.now()
        });
      });
    }

    setState(() => _isLoading = false);
    _scrollToBottom();
    _saveChat();
  }

  void _saveChat() {
    final chats = box.read<List>('support_chats') ?? [];
    if (_messages.length >= 2) {
      final lastMsg = _messages.last;
      final lastText = lastMsg['text'].toString();
      chats.add({
        'last_message': lastText.length > 50
            ? '${lastText.substring(0, 50)}...'
            : lastText,
        'time': DateTime.now().toIso8601String(),
        'messages': _messages,
        'chat_start': _chatStartTime?.toIso8601String(),
      });
      box.write('support_chats', chats);
    }
  }

  String _formatChatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now'.tr;
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return DateFormat('h:mm a').format(dt);
    }
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  String _formatHeaderTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return DateFormat('h:mm a').format(dt);
    }
    if (now.difference(dt).inDays == 1) return 'Yesterday'.tr;
    if (now.difference(dt).inDays < 7) {
      return '${now.difference(dt).inDays} ${'days ago'.tr}';
    }
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  void _showAttachSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.camera_copy),
              title: Text('Take a photo'.tr),
              onTap: () {
                Navigator.pop(ctx);
                _showAgentOnlyFeature();
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.gallery_copy),
              title: Text('Upload a file'.tr),
              onTap: () {
                Navigator.pop(ctx);
                _showAgentOnlyFeature();
              },
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel'.tr),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAgentOnlyFeature() {
    if (Get.context == null) return;
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        content: Text('File sharing is available when connected to an agent.'.tr),
        backgroundColor: AppColors.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        leading: const BackIconWidget(),
        centerTitle: false,
        titleSpacing: 0,
        title: Text('Virtual Assistant'.tr,
            style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isTyping ? 1 : 0) + 1,
              itemBuilder: (ctx, i) {
                if (i == 0 && _chatStartTime != null) {
                  return _buildTimeHeader(_chatStartTime!);
                }
                final msgIndex = i - 1;
                if (_isTyping && msgIndex == _messages.length) {
                  return _buildTypingBubble(isDark);
                }
                if (msgIndex < _messages.length) {
                  final msg = _messages[msgIndex];
                  final isBot = msg['role'] == 'bot';
                  final time = msg['time'] as DateTime;
                  return _buildMessageRow(isBot, msg['text'], time, isDark);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          if (_chatEnded)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('── ${'Chat Ended'.tr} ──',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  Text('Please start a new conversation later.'.tr,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
          if (!_chatEnded)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCardColor
                            : AppColors.lightCardColor,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: IconButton(
                        icon: Icon(Iconsax.link_21_copy,
                            size: 20,
                            color: _isLoading
                                ? Colors.grey.shade400
                                : AppColors.primaryColor),
                        onPressed: _isLoading ? null : _showAttachSheet,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardColor
                              : AppColors.lightCardColor,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _msgCtrl,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            hintText: 'Type a message...'.tr,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: IconButton(
                        icon: const Icon(Iconsax.send_1_copy,
                            size: 20, color: Colors.white),
                        onPressed: _isLoading ? null : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeHeader(DateTime time) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(_formatHeaderTime(time),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ),
    );
  }

  Widget _buildMessageRow(
      bool isBot, String text, DateTime time, bool isDark) {
    if (isBot) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset('assets/icons/customer_support.png',
                  width: 30, height: 30),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade900)),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(_formatChatTime(time),
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade500)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: SizedBox()),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text,
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade900)),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(_formatChatTime(time),
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade500)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _hasUserAvatar
                  ? Image.network(_userAvatar,
                      width: 30,
                      height: 30,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                          'assets/icons/profile.png',
                          width: 30,
                          height: 30))
                  : Image.asset('assets/icons/profile.png',
                      width: 30, height: 30),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTypingBubble(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset('assets/icons/customer_support.png',
                width: 30, height: 30),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: AnimatedBuilder(
              animation: _typingAnim,
              builder: (ctx, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(7, (i) {
                    final offset =
                        (sin((_typingAnim.value * 2 * pi) + (i * 0.5)) + 1) / 2;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey
                            .withValues(alpha: 0.2 + (offset * 0.8)),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
