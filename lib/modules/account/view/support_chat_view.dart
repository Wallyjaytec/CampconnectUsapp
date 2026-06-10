import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/login_service.dart';
import '../../../shared/widgets/back_icon_widget.dart';
import '../controller/customer_basic_info_controller.dart';

class SupportChatView extends StatefulWidget {
  final List<Map<String, dynamic>>? existingMessages;
  final String? existingChatId;
  final DateTime? existingChatStartTime;
  const SupportChatView(
      {super.key,
      this.existingMessages,
      this.existingChatId,
      this.existingChatStartTime});

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
  bool _showSuggestions = true;
  DateTime? _chatStartTime;
  String? _chatId;
  Timer? _timer;

  late AnimationController _typingAnimCtrl;
  late Animation<double> _dot1;
  late Animation<double> _dot2;
  late Animation<double> _dot3;
  final AudioPlayer _audioPlayer = AudioPlayer();

  String get _userAvatar {
    try {
      final ctrl = Get.find<CustomerBasicInfoController>();
      if (ctrl.pickedImagePath.value.isNotEmpty) {
        return ctrl.pickedImagePath.value;
      }
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

  String get _firstName {
    try {
      final ctrl = Get.find<CustomerBasicInfoController>();
      final fullName = ctrl.name.value.trim();
      if (fullName.isNotEmpty) return fullName.split(' ').first;
    } catch (_) {}
    return '';
  }

  @override
  void initState() {
    super.initState();

    _typingAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));

    _dot1 = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _typingAnimCtrl, curve: const Interval(0.0, 0.4)));
    _dot2 = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _typingAnimCtrl, curve: const Interval(0.2, 0.6)));
    _dot3 = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _typingAnimCtrl, curve: const Interval(0.4, 0.8)));

    if (widget.existingChatId != null) {
      _chatId = widget.existingChatId;
      _chatStartTime = widget.existingChatStartTime;
    } else {
      _chatStartTime = DateTime.now();
      _chatId = _chatStartTime!.millisecondsSinceEpoch.toString();
    }
    _startTimer();

    if (widget.existingMessages != null && widget.existingMessages!.isNotEmpty) {
      _messages.addAll(widget.existingMessages!);
      _showSuggestions = false;
      for (final m in widget.existingMessages!) {
        _history.add({'role': m['role'], 'content': m['text']});
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      if (_messages.isEmpty) _sendWelcomeMessage();
    });

    _loadFromServer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _typingAnimCtrl.dispose();
    _audioPlayer.dispose();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
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
    _playTypingSound();
  }

  void _stopTypingAnimation() {
    _typingAnimCtrl.stop();
    _stopTypingSound();
  }

  void _playTypingSound() {
    try {
      _audioPlayer.setSource(AssetSource('sounds/typing_sounds.m4a'));
      _audioPlayer.setReleaseMode(ReleaseMode.loop);
      _audioPlayer.resume();
    } catch (_) {}
  }

  void _stopTypingSound() {
    try {
      _audioPlayer.stop();
    } catch (_) {}
  }

  void _sendWelcomeMessage() {
    final name = _firstName;
    final greeting = name.isNotEmpty
        ? '${'Hello'.tr} $name, ${'I\'m Luca, your CampConnectUs Virtual Assistant. Just pick a topic or feel free to type your question.'.tr}'
        : '${'Hello'.tr}! ${'I\'m Luca, your CampConnectUs Virtual Assistant. Just pick a topic or feel free to type your question.'.tr}';

    setState(() {
      _messages.add({'role': 'bot', 'text': greeting, 'time': DateTime.now()});
      _history.add({'role': 'assistant', 'content': greeting});
    });
    _scrollToBottom();
    _saveChat();
  }

  Future<void> _sendMessage({String? prefill}) async {
    final text = prefill ?? _msgCtrl.text.trim();
    if (text.isEmpty || _isLoading || _chatEnded) return;

    setState(() {
      _showSuggestions = false;
      _messages.add({'role': 'user', 'text': text, 'time': DateTime.now()});
      _history.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    if (prefill == null) _msgCtrl.clear();
    _scrollToBottom();

    setState(() => _isTyping = true);
    _startTypingAnimation();
    _scrollToBottom();

    try {
      final uri = Uri.parse(AppConfig.chatbotChatUrl());
      final response = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'message': text,
            'history': _history.sublist(0, max(0, _history.length - 1)),
          }));

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
    if (_messages.length < 2) return;
    final chats = box.read<List>('support_chats') ?? [];

    chats.removeWhere((c) => c['id'] == _chatId);

    final lastMsg = _messages.last;
    final lastText = lastMsg['text'].toString();
    chats.add({
      'id': _chatId,
      'last_message':
          lastText.length > 50 ? '${lastText.substring(0, 50)}...' : lastText,
      'time': DateTime.now().toIso8601String(),
      'messages': List.from(_messages),
      'chat_start': _chatStartTime?.toIso8601String(),
    });

    box.write('support_chats', chats);
    _syncToServer();
  }

  Future<void> _syncToServer() async {
    try {
      final token = LoginService().token;
      if (token == null || token.isEmpty) return;
      final uri = Uri.parse(AppConfig.chatbotHistoryUrl());
      await http.post(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }, body: jsonEncode({
        'action': 'save',
        'chats': box.read<List>('support_chats') ?? [],
      }));
    } catch (_) {}
  }

  Future<void> _loadFromServer() async {
    try {
      final token = LoginService().token;
      if (token == null || token.isEmpty) return;
      final uri = Uri.parse(AppConfig.chatbotHistoryUrl());
      final resp = await http.post(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }, body: jsonEncode({'action': 'load'}));
      final data = jsonDecode(resp.body);
      if (data['success'] == true && data['chats'] != null) {
        final serverChats = data['chats'] as List;
        if (serverChats.isNotEmpty) {
          box.write('support_chats', serverChats);
        }
      }
    } catch (_) {}
  }

  String _formatChatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day &&
        dt.month == now.month &&
        dt.year == now.year) {
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

  void _showCopyOption(String text, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: [
        PopupMenuItem(
          child: Row(children: [
            const Icon(Iconsax.copy_copy, size: 18),
            const SizedBox(width: 8),
            Text('Copy'.tr),
          ]),
          onTap: () {
            Clipboard.setData(ClipboardData(text: text));
          },
        ),
      ],
    );
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
                    child: Text('Cancel'.tr))),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAgentOnlyFeature() {
    if (Get.context == null) return;
    ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(
      content: Text(
          'File sharing is available when connected to an agent.'.tr),
      backgroundColor: AppColors.primaryColor,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userTextColor = isDark ? Colors.white : Colors.grey.shade900;
    final botTextColor = isDark ? Colors.white : Colors.grey.shade900;
    final botBubbleColor =
        isDark ? Colors.deepOrange.shade300 : Colors.grey.shade200;
    final userBubbleColor = isDark
        ? AppColors.primaryColor.withValues(alpha: 0.3)
        : AppColors.primaryColor.withValues(alpha: 0.15);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        leading: const BackIconWidget(),
        centerTitle: false,
        titleSpacing: 0,
        title: Text('Virtual Assistant'.tr,
            style:
                const TextStyle(fontWeight: FontWeight.normal, fontSize: 18)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length +
                  (_isTyping ? 1 : 0) +
                  1 +
                  (_showSuggestions && _messages.length == 1 ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == 0 && _chatStartTime != null) {
                  return _buildTimeHeader(_chatStartTime!);
                }
                final msgIndex = i - 1;
                if (_showSuggestions &&
                    _messages.length == 1 &&
                    msgIndex == _messages.length) {
                  return _buildSuggestions();
                }
                if (_isTyping &&
                    msgIndex ==
                        _messages.length +
                            (_showSuggestions && _messages.length == 1
                                ? 1
                                : 0)) {
                  return _buildTypingBubble(botBubbleColor);
                }
                if (msgIndex < _messages.length) {
                  final msg = _messages[msgIndex];
                  final isBot = msg['role'] == 'bot';
                  final time = msg['time'] as DateTime;
                  return _buildMessageRow(isBot, msg['text'], time,
                      userTextColor, botTextColor,
                      userBubbleColor: userBubbleColor,
                      botBubbleColor: botBubbleColor,
                      screenWidth: screenWidth);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          if (_chatEnded)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Text('── ${'Chat Ended'.tr} ──',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                Text('Please start a new conversation later.'.tr,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
              ]),
            ),
          if (!_chatEnded)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(children: [
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
                        borderRadius: BorderRadius.circular(25)),
                    child: IconButton(
                      icon: const Icon(Iconsax.send_1_copy,
                          size: 20, color: Colors.white),
                      onPressed: _isLoading ? null : () => _sendMessage(),
                    ),
                  ),
                ]),
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

  Widget _buildSuggestions() {
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('💡 ${'Frequently Asked'.tr}',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: suggestions.map((s) {
              return ActionChip(
                label: Text(s.tr, style: const TextStyle(fontSize: 11)),
                onPressed: () => _sendMessage(prefill: s),
                backgroundColor:
                    AppColors.primaryColor.withValues(alpha: 0.08),
                side: BorderSide(
                    color: AppColors.primaryColor.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageRow(
      bool isBot, String text, DateTime time, Color userTextColor,
      Color botTextColor,
      {required Color userBubbleColor,
      required Color botBubbleColor,
      required double screenWidth}) {
    if (isBot) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset('assets/icons/customer_support.png',
                  width: 28, height: 28),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: GestureDetector(
                onLongPressStart: (details) {
                  _showCopyOption(text, details.globalPosition);
                },
                child: Container(
                  constraints:
                      BoxConstraints(maxWidth: screenWidth * 0.75),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: botBubbleColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(text,
                          style: TextStyle(
                              fontSize: 14, color: botTextColor)),
                      const SizedBox(height: 2),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(_formatChatTime(time),
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: SizedBox()),
            Flexible(
              child: GestureDetector(
                onLongPressStart: (details) {
                  _showCopyOption(text, details.globalPosition);
                },
                child: Container(
                  constraints:
                      BoxConstraints(maxWidth: screenWidth * 0.75),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: userBubbleColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(4),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(text,
                          style: TextStyle(
                              fontSize: 14, color: userTextColor)),
                      const SizedBox(height: 2),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(_formatChatTime(time),
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _hasUserAvatar
                  ? Image.network(_userAvatar,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                          'assets/icons/profile.png',
                          width: 28,
                          height: 28))
                  : Image.asset('assets/icons/profile.png',
                      width: 28, height: 28),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTypingBubble(Color botBubbleColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset('assets/icons/customer_support.png',
                width: 28, height: 28),
          ),
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: botBubbleColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: AnimatedBuilder(
              animation: _typingAnimCtrl,
              builder: (ctx, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDot(_dot1, 0),
                    const SizedBox(width: 4),
                    _buildDot(_dot2, 1),
                    const SizedBox(width: 4),
                    _buildDot(_dot3, 2),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Animation<double> anim, int index) {
    return AnimatedBuilder(
      animation: anim,
      builder: (ctx, child) {
        final offset = sin((anim.value * 2 * pi));
        return Transform.translate(
          offset: Offset(0, offset * 3),
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3 + (anim.value * 0.7)),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
