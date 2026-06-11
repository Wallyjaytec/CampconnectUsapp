import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/login_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../shared/widgets/back_icon_widget.dart';
import '../controller/customer_basic_info_controller.dart';

class SupportChatView extends StatefulWidget {
  const SupportChatView({super.key});

  @override
  State<SupportChatView> createState() => _SupportChatViewState();
}

class _SupportChatViewState extends State<SupportChatView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final List<Map<String, String>> _history = [];
  final box = GetStorage();
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;
  bool _isTyping = false;
  bool _chatEnded = false;
  bool _showSuggestions = true;
  bool _isAgentConnected = false;
  String? _agentName;
  DateTime? _chatStartTime;
  String? _chatId;
  Timer? _timer;
  Timer? _typingDelayTimer;
  Timer? _agentPollTimer;
  Timer? _typingIndicatorTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _copyVisibleIndex;
  bool _isRecording = false;

  late AnimationController _typingAnimCtrl;
  late Animation<double> _dot1;
  late Animation<double> _dot2;
  late Animation<double> _dot3;

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

  String get _firstName {
    try {
      final ctrl = Get.find<CustomerBasicInfoController>();
      final fullName = ctrl.name.value.trim();
      if (fullName.isNotEmpty) return fullName.split(' ').first;
    } catch (_) {}
    return '';
  }

  String get _userFullName {
    try {
      final ctrl = Get.find<CustomerBasicInfoController>();
      final n = ctrl.name.value.trim();
      return n.isNotEmpty ? n : 'You'.tr;
    } catch (_) {}
    return 'You'.tr;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _typingAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _dot1 = Tween<double>(begin: -1.0, end: 1.0).animate(CurvedAnimation(parent: _typingAnimCtrl, curve: const Interval(0.0, 0.33)));
    _dot2 = Tween<double>(begin: -1.0, end: 1.0).animate(CurvedAnimation(parent: _typingAnimCtrl, curve: const Interval(0.33, 0.66)));
    _dot3 = Tween<double>(begin: -1.0, end: 1.0).animate(CurvedAnimation(parent: _typingAnimCtrl, curve: const Interval(0.66, 1.0)));

    final args = Get.arguments;
    if (args is Map) {
      if (args['messages'] != null) {
        final msgs = (args['messages'] as List).cast<Map<String, dynamic>>();
        _messages.addAll(msgs);
        _showSuggestions = false;
        for (final m in msgs) { _history.add({'role': m['role'], 'content': m['text']}); }
      }
      _chatId = args['chatId']?.toString();
      _chatStartTime = args['chatStartTime'] != null ? DateTime.parse(args['chatStartTime'].toString()) : null;
    }

    if (_chatId == null) { _chatStartTime = DateTime.now(); _chatId = _chatStartTime!.millisecondsSinceEpoch.toString(); }
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) { _scrollToBottom(); if (_messages.isEmpty) _sendWelcomeMessage(); });
    _loadFromServer();
  }

  @override
  void didChangePlatformBrightness() { if (mounted) setState(() {}); }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopTypingAnimation();
      _saveChat();
      _syncToServer();
    }
  }

  @override
  void dispose() {
    _stopAgentPolling();
    _stopTypingAnimation();
    _stopTypingIndicator();
    _saveChat();
    _syncToServer();
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel(); _typingDelayTimer?.cancel(); _typingIndicatorTimer?.cancel();
    _typingAnimCtrl.dispose(); _audioPlayer.dispose();
    _msgCtrl.dispose(); _scrollCtrl.dispose();
    super.dispose();
  }

  void _startTimer() { _timer = Timer.periodic(const Duration(seconds: 30), (_) { if (mounted) setState(() {}); }); }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _startTypingAnimation() {
    _typingAnimCtrl.repeat();
    try { _audioPlayer.stop(); _audioPlayer.play(AssetSource('sounds/typing_sound.m4a')); _audioPlayer.setReleaseMode(ReleaseMode.loop); } catch (_) {}
  }

  void _stopTypingAnimation() { _typingAnimCtrl.stop(); _typingAnimCtrl.reset(); try { _audioPlayer.stop(); } catch (_) {} }

  void _startTypingIndicator() {
    _stopTypingIndicator();
    _typingIndicatorTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted && _isAgentConnected && !_chatEnded) {
        setState(() {});
      }
    });
  }

  void _stopTypingIndicator() {
    _typingIndicatorTimer?.cancel();
    _typingIndicatorTimer = null;
  }

  void _cancelRequest() {
    setState(() { _stopTypingAnimation(); _isTyping = false; _isLoading = false; });
    _typingDelayTimer?.cancel();
  }

  void _startAgentPolling() {
    _isAgentConnected = true;
    _startTypingIndicator();
    _agentPollTimer?.cancel();
    _agentPollTimer = Timer.periodic(const Duration(seconds: 5), (_) { _pollAgentReplies(); });
  }

  void _stopAgentPolling() {
    _agentPollTimer?.cancel();
    _isAgentConnected = false;
    _agentName = null;
    _stopTypingIndicator();
  }

  Future<void> _pollAgentReplies() async {
    try {
      final token = LoginService().token;
      if (token == null || token.isEmpty) return;
      final uri = Uri.parse(AppConfig.agentPollRepliesUrl());
      final resp = await http.post(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });
      final data = jsonDecode(resp.body);
      if (data['success'] == true && data['replies'] != null) {
        for (final reply in data['replies']) {
          final msgText = reply['message']?.toString() ?? '';
          final agentName = reply['agent_name']?.toString() ?? 'Agent';
          final msgType = reply['type']?.toString() ?? 'text';
          final mediaUrl = reply['media_url']?.toString() ?? '';
          
          // Check for agent joined message
          if (msgText.startsWith('__AGENT_JOINED__')) {
            final name = msgText.replaceAll('__AGENT_JOINED__', '');
            setState(() {
              _agentName = name;
              _stopTypingIndicator();
            });
            continue;
          }
          
          // Check for chat ended message
          if (msgText.contains('chat session has been ended') || 
              msgText.contains('This chat session has been ended')) {
            setState(() {
              _chatEnded = true;
              _isAgentConnected = false;
              _stopTypingIndicator();
              _messages.add({
                'role': 'bot',
                'text': msgText,
                'time': DateTime.tryParse(reply['time']?.toString() ?? '') ?? DateTime.now(),
                'type': 'text',
              });
            });
            _stopAgentPolling();
            _saveChat();
            return;
          }
          
          // Regular message
          setState(() {
            _stopTypingIndicator();
            _typingIndicatorTimer?.cancel();
            _typingIndicatorTimer = Timer(const Duration(seconds: 3), () {
              // Resume typing indicator after 3 seconds
            });
            
            if (msgType == 'image') {
              _messages.add({
                'role': 'bot',
                'text': mediaUrl,
                'agentName': agentName,
                'time': DateTime.tryParse(reply['time']?.toString() ?? '') ?? DateTime.now(),
                'type': 'image',
              });
            } else if (msgType == 'voice') {
              _messages.add({
                'role': 'bot',
                'text': mediaUrl,
                'agentName': agentName,
                'time': DateTime.tryParse(reply['time']?.toString() ?? '') ?? DateTime.now(),
                'type': 'voice',
              });
            } else {
              _messages.add({
                'role': 'bot',
                'text': msgText,
                'agentName': agentName,
                'time': DateTime.tryParse(reply['time']?.toString() ?? '') ?? DateTime.now(),
                'type': 'text',
              });
            }
          });
        }
        if ((data['replies'] as List).isNotEmpty) {
          _scrollToBottom();
          _saveChat();
        }
      }
    } catch (_) {}
  }

  void _sendWelcomeMessage() {
    final name = _firstName;
    final greeting = name.isNotEmpty
        ? '${'Hello'.tr} $name, ${'I\'m Luca, your CampConnectUs Virtual Assistant. Just pick a topic or feel free to type your question.'.tr}'
        : '${'Hello'.tr}! ${'I\'m Luca, your CampConnectUs Virtual Assistant. Just pick a topic or feel free to type your question.'.tr}';
    setState(() { 
      _messages.add({'role': 'bot', 'text': greeting, 'time': DateTime.now(), 'type': 'text'}); 
      _history.add({'role': 'assistant', 'content': greeting}); 
    });
    _scrollToBottom(); _saveChat();
  }

  Future<void> _sendMessage({String? prefill, String? imagePath}) async {
    final text = imagePath != null ? '' : (prefill ?? _msgCtrl.text.trim()).tr;
    if ((text.isEmpty && imagePath == null) || _isLoading || _chatEnded) return;
    
    if (imagePath != null) {
      // Send image
      setState(() {
        _messages.add({'role': 'user', 'text': imagePath, 'time': DateTime.now(), 'type': 'image'});
      });
    } else {
      setState(() { 
        _showSuggestions = false; 
        _messages.add({'role': 'user', 'text': text, 'time': DateTime.now(), 'type': 'text'}); 
        _history.add({'role': 'user', 'content': text}); 
      });
    }
    
    if (prefill == null && imagePath == null) _msgCtrl.clear();
    _scrollToBottom();
    
    // If connected to agent, send silently (no bot reply)
    if (_isAgentConnected) {
      setState(() => _isLoading = true);
      try {
        String? token;
        for (int i = 0; i < 5; i++) {
          token = LoginService().token;
          if (token != null && token.isNotEmpty) break;
          await Future.delayed(const Duration(milliseconds: 500));
        }
        
        final uri = Uri.parse(AppConfig.chatbotChatUrl());
        var body = <String, dynamic>{'message': imagePath != null ? '[Image sent]' : text, 'history': _history.sublist(0, max(0, _history.length - 1))};
        
        if (imagePath != null) {
          var request = http.MultipartRequest('POST', uri);
          request.headers['Authorization'] = 'Bearer ${token ?? ''}';
          request.fields['message'] = '[Image sent]';
          request.fields['history'] = jsonEncode(_history.sublist(0, max(0, _history.length - 1)));
          request.files.add(await http.MultipartFile.fromPath('image', imagePath));
          await request.send().timeout(const Duration(seconds: 35));
        } else {
          await http.post(uri, headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${token ?? ''}',
          }, body: jsonEncode(body)).timeout(const Duration(seconds: 35));
        }
      } catch (e) {}
      if (mounted) setState(() => _isLoading = false);
      _saveChat();
      return;
    }
    
    // Normal bot flow
    setState(() => _isLoading = true);
    setState(() => _isTyping = true);
    _startTypingAnimation(); 
    _scrollToBottom();
    
    final completer = Completer<void>();
    _typingDelayTimer = Timer(const Duration(seconds: 6), () => completer.complete());
    await completer.future;
    
    if (!mounted || !_isLoading) return;
    try {
      String? token;
      for (int i = 0; i < 5; i++) {
        token = LoginService().token;
        if (token != null && token.isNotEmpty) break;
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      final uri = Uri.parse(AppConfig.chatbotChatUrl());
      final response = await http.post(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${token ?? ''}',
      }, body: jsonEncode({'message': text, 'history': _history.sublist(0, max(0, _history.length - 1))})).timeout(const Duration(seconds: 35));
      
      if (!mounted || !_isLoading) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _stopTypingAnimation();
            _isTyping = false;
            _messages.add({'role': 'bot', 'text': data['reply'], 'time': DateTime.now(), 'type': 'text'});
            _history.add({'role': 'assistant', 'content': data['reply']});
            if (data['action'] == 'agent_connected') _startAgentPolling();
          });
        } else { _showError(); }
      } else { _showError(); }
    } catch (e) { _showError(); }
    if (mounted) { setState(() => _isLoading = false); _scrollToBottom(); _saveChat(); }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        await _sendMessage(imagePath: image.path);
      }
    } catch (e) {
      if (Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(content: Text('Could not pick image'.tr), backgroundColor: AppColors.primaryColor, behavior: SnackBarBehavior.floating));
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (photo != null) {
        await _sendMessage(imagePath: photo.path);
      }
    } catch (e) {
      if (Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(content: Text('Could not take photo'.tr), backgroundColor: AppColors.primaryColor, behavior: SnackBarBehavior.floating));
      }
    }
  }

  Future<void> _onMicPressed() async {
    if (!_isAgentConnected) { 
      if (Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(content: Text('Voice messaging is available when connected to an agent.'.tr), backgroundColor: AppColors.primaryColor, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 3)));
      }
      return; 
    }
    final ok = await PermissionService.I.canUseMicrophoneOrExplain();
    if (ok) {
      if (_isRecording) {
        // Stop recording
        setState(() => _isRecording = false);
      } else {
        // Start recording
        setState(() => _isRecording = true);
        if (Get.context != null) {
          ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(content: Text('Recording started...'.tr), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 1)));
        }
        // Auto-stop after 60 seconds
        Future.delayed(const Duration(seconds: 60), () {
          if (mounted && _isRecording) {
            setState(() => _isRecording = false);
            if (Get.context != null) {
              ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(content: Text('Voice recording sent'.tr), backgroundColor: AppColors.primaryColor, behavior: SnackBarBehavior.floating));
            }
          }
        });
      }
    }
  }

  String _formatMarkdown(String text) => text.replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (m) => '<b>${m.group(1)}</b>').replaceAll('\n', '<br>');

  void _showError() {
    if (!mounted) return;
    setState(() { _stopTypingAnimation(); _isTyping = false; _messages.add({'role': 'bot', 'text': "We're sorry for the inconvenience. Currently we are unable to reply. Please request an agent or contact us:\n\n📧 support@campconnectus.store\n📞 +2348155763709, +2348144317152\n\nThank you.".tr, 'time': DateTime.now(), 'type': 'text'}); _isLoading = false; });
    _scrollToBottom(); _saveChat();
  }

  void _saveChat() {
    if (_messages.length < 2) return;
    final chats = box.read<List>('support_chats') ?? [];
    chats.removeWhere((c) => c['id'] == _chatId);
    final lastMsg = _messages.last; final lastText = lastMsg['text'].toString();
    chats.add({'id': _chatId, 'last_message': lastText.length > 50 ? '${lastText.substring(0, 50)}...' : lastText, 'time': DateTime.now().toIso8601String(), 'messages': List.from(_messages), 'chat_start': _chatStartTime?.toIso8601String()});
    box.write('support_chats', chats);
    if (chats.isNotEmpty) _syncToServer();
  }

  Future<void> _syncToServer() async {
    try {
      final token = LoginService().token; if (token == null || token.isEmpty) return;
      final chats = box.read<List>('support_chats'); if (chats == null || chats.isEmpty) return;
      await http.post(Uri.parse(AppConfig.chatbotHistoryUrl()), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: jsonEncode({'action': 'save', 'chats': chats}));
    } catch (_) {}
  }

  Future<void> _loadFromServer() async {
    try {
      String? token;
      for (int i = 0; i < 5; i++) { token = LoginService().token; if (token != null && token.isNotEmpty) break; await Future.delayed(const Duration(milliseconds: 500)); }
      if (token == null || token.isEmpty) return;
      final resp = await http.post(Uri.parse(AppConfig.chatbotHistoryUrl()), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: jsonEncode({'action': 'load'}));
      final data = jsonDecode(resp.body);
      if (data['success'] == true && data['chats'] != null) { final serverChats = data['chats'] as List; if (serverChats.isNotEmpty) box.write('support_chats', serverChats); }
    } catch (_) {}
  }

  String _formatChatTime(DateTime dt) { final now = DateTime.now(); if (dt.day == now.day && dt.month == now.month && dt.year == now.year) return DateFormat('h:mm a').format(dt); return DateFormat('dd/MM/yyyy').format(dt); }
  String _formatHeaderTime(DateTime dt) { final now = DateTime.now(); if (dt.day == now.day && dt.month == now.month && dt.year == now.year) return DateFormat('h:mm a').format(dt); if (now.difference(dt).inDays == 1) return 'Yesterday'.tr; if (now.difference(dt).inDays < 7) return '${now.difference(dt).inDays} ${'days ago'.tr}'; return DateFormat('dd/MM/yyyy').format(dt); }

  void _copyMessage(String text) { HapticFeedback.mediumImpact(); Clipboard.setData(ClipboardData(text: text)); setState(() => _copyVisibleIndex = null); }
  void _dismissCopy() { if (_copyVisibleIndex != null) setState(() => _copyVisibleIndex = null); }

  void _showAttachSheet() {
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Iconsax.camera, color: AppColors.primaryColor), title: Text('Take a photo'.tr), onTap: () { Navigator.pop(ctx); _takePhoto(); }),
      ListTile(leading: const Icon(Iconsax.gallery, color: AppColors.primaryColor), title: Text('Upload from gallery'.tr), onTap: () { Navigator.pop(ctx); _pickImage(); }),
      ListTile(leading: const Icon(Iconsax.document, color: AppColors.primaryColor), title: Text('Send file'.tr), onTap: () { Navigator.pop(ctx); _pickImage(); }),
      const SizedBox(height: 12), Center(child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel'.tr))), const SizedBox(height: 8),
    ])));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userTextColor = isDark ? Colors.white : Colors.grey.shade900;
    final botTextColor = isDark ? Colors.white : Colors.grey.shade900;
    final botBubbleColor = isDark ? Colors.deepOrange.shade300 : Colors.grey.shade200;
    final userBubbleColor = isDark ? AppColors.primaryColor.withValues(alpha: 0.35) : AppColors.primaryColor.withValues(alpha: 0.15);
    final screenWidth = MediaQuery.of(context).size.width;
    final copyIconColor = isDark ? Colors.white : Colors.black;
    final showTypingDots = _isAgentConnected && !_chatEnded && _agentName == null;

    return GestureDetector(
      onTap: _dismissCopy,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, 
          leadingWidth: 44, 
          leading: const BackIconWidget(), 
          centerTitle: false, 
          titleSpacing: 0, 
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Virtual Assistant'.tr, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18)),
              if (_agentName != null)
                Text('${'Agent'.tr}: $_agentName', style: TextStyle(fontSize: 12, color: AppColors.primaryColor, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        body: Column(children: [
          Expanded(child: ListView.builder(controller: _scrollCtrl, padding: const EdgeInsets.all(12), itemCount: _messages.length + (_isTyping || showTypingDots ? 1 : 0) + 1 + (_showSuggestions && _messages.length == 1 ? 1 : 0), itemBuilder: (ctx, i) {
            if (i == 0 && _chatStartTime != null) return _buildTimeHeader(_chatStartTime!);
            final msgIndex = i - 1;
            if (_showSuggestions && _messages.length == 1 && msgIndex == _messages.length) return _buildSuggestions();
            if ((_isTyping || showTypingDots) && msgIndex == _messages.length + (_showSuggestions && _messages.length == 1 ? 1 : 0)) return _buildTypingBubble(botBubbleColor, showTypingDots ? 'Waiting for agent...' : null);
            if (msgIndex >= 0 && msgIndex < _messages.length) { 
              final msg = _messages[msgIndex]; 
              final isBot = msg['role'] == 'bot'; 
              final rawTime = msg['time']; 
              final time = rawTime is DateTime ? rawTime : DateTime.parse(rawTime.toString()); 
              final msgType = msg['type']?.toString() ?? 'text';
              final agentName = msg['agentName']?.toString();
              return _buildMessageRow(isBot, msg['text'], time, userTextColor, botTextColor, userBubbleColor: userBubbleColor, botBubbleColor: botBubbleColor, screenWidth: screenWidth, msgIndex: msgIndex, copyIconColor: copyIconColor, msgType: msgType, agentName: agentName); 
            }
            return const SizedBox.shrink();
          })),
          if (_chatEnded) Padding(padding: const EdgeInsets.all(24), child: Column(children: [Text('── ${'Chat Ended'.tr} ──', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade500)), const SizedBox(height: 4), Text('Please start a new conversation later.'.tr, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))])),
          if (!_chatEnded) SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
            const SizedBox(width: 4),
            Container(decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.grey.shade300)), child: IconButton(icon: Icon(Iconsax.attach_circle, size: 20, color: _isAgentConnected ? (_isLoading ? Colors.grey.shade400 : AppColors.primaryColor) : Colors.grey.shade400), onPressed: _isAgentConnected && !_isLoading ? _showAttachSheet : null)),
            const SizedBox(width: 6),
            Expanded(child: Container(decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.grey.shade300)), child: TextField(controller: _msgCtrl, enabled: !_isLoading && !_chatEnded, decoration: InputDecoration(hintText: _chatEnded ? 'Chat has ended'.tr : _isAgentConnected ? (_agentName != null ? 'Message $_agentName...'.tr : 'Waiting for agent...'.tr) : 'Type a message...'.tr, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16)), onSubmitted: (_) => _sendMessage()))),
            const SizedBox(width: 6),
            Container(decoration: BoxDecoration(color: _isRecording ? Colors.red : (_isAgentConnected ? AppColors.primaryColor : (isDark ? Colors.grey.shade700 : Colors.grey.shade300)), borderRadius: BorderRadius.circular(25)), child: IconButton(icon: Icon(_isRecording ? Iconsax.microphone_slash : Iconsax.microphone_2, size: 20, color: _isAgentConnected || _isRecording ? Colors.white : (isDark ? Colors.grey.shade500 : Colors.grey.shade500)), onPressed: _onMicPressed)),
            const SizedBox(width: 4),
            Container(decoration: BoxDecoration(color: _isLoading ? Colors.orange : AppColors.primaryColor, borderRadius: BorderRadius.circular(25)), child: IconButton(padding: const EdgeInsets.all(8), icon: Icon(_isLoading ? Icons.stop_rounded : Iconsax.send_1_copy, size: 24, color: Colors.white), onPressed: _isLoading ? _cancelRequest : () => _sendMessage())),
          ]))),
        ]),
      ),
    );
  }

  Widget _buildTimeHeader(DateTime time) => Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(_formatHeaderTime(time), style: TextStyle(fontSize: 12, color: Colors.grey.shade500))));
  
  Widget _buildSuggestions() { final s = ['How do I track my order?','What is the return policy?','How to request a refund?','How to recharge my wallet?','What payment methods are available?','How to close my account?','How to report a seller?','What shipping methods do you offer?']; return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('💡 ${'Frequently Asked'.tr}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)), const SizedBox(height: 8), Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: s.map((x) => ActionChip(label: Text(x.tr, style: const TextStyle(fontSize: 11)), onPressed: () => _sendMessage(prefill: x.tr), backgroundColor: AppColors.primaryColor.withValues(alpha: 0.08), side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)))).toList())])); }

  Widget _buildMessageRow(bool isBot, String text, DateTime time, Color userTextColor, Color botTextColor, {required Color userBubbleColor, required Color botBubbleColor, required double screenWidth, required int msgIndex, required Color copyIconColor, String msgType = 'text', String? agentName}) {
    final name = isBot ? (agentName ?? 'Luca') : _userFullName;
    final formattedText = _formatMarkdown(text);
    final showCopy = _copyVisibleIndex == msgIndex;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (isBot) ...[
          ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.asset('assets/icons/customer_support.png', width: 28, height: 28)),
          const SizedBox(width: 6),
        ] else const Expanded(child: SizedBox()),
        Flexible(
          child: GestureDetector(
            onLongPressStart: (_) { HapticFeedback.mediumImpact(); setState(() => _copyVisibleIndex = msgIndex); },
            child: Container(
              constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: isBot ? botBubbleColor : userBubbleColor, borderRadius: isBot ? const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(16), bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)) : const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(4), bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))),
              child: Stack(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Padding(padding: EdgeInsets.only(right: showCopy ? 22 : 0), child: Text(name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: (isBot ? botTextColor : userTextColor).withValues(alpha: 0.7)))),
                  const SizedBox(height: 2),
                  if (msgType == 'image')
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: text.startsWith('http') ? text : AppConfig.assetUrl(text), width: screenWidth * 0.6, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Iconsax.gallery_remove)))
                  else if (msgType == 'voice')
                    Row(mainAxisSize: MainAxisSize.min, children: [Icon(Iconsax.musicnote, size: 20, color: AppColors.primaryColor), const SizedBox(width: 8), Text('🎤 Voice message'.tr, style: TextStyle(fontSize: 14, color: AppColors.primaryColor, fontStyle: FontStyle.italic))])
                  else
                    HtmlWidget(formattedText, textStyle: TextStyle(fontSize: 14, color: isBot ? botTextColor : userTextColor)),
                  const SizedBox(height: 2),
                  Align(alignment: Alignment.bottomRight, child: Text(_formatChatTime(time), style: TextStyle(fontSize: 10, color: Colors.grey.shade500))),
                ]),
                if (showCopy) Positioned(top: 0, right: 0, child: GestureDetector(onTap: () => _copyMessage(text), child: Icon(Iconsax.copy_copy, size: 18, color: copyIconColor))),
              ]),
            ),
          ),
        ),
        if (!isBot) ...[
          const SizedBox(width: 6),
          ClipRRect(borderRadius: BorderRadius.circular(20), child: _hasUserAvatar ? Image.network(_userAvatar, width: 28, height: 28, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset('assets/icons/profile.png', width: 28, height: 28)) : Image.asset('assets/icons/profile.png', width: 28, height: 28)),
        ],
      ]),
    );
  }

  Widget _buildTypingBubble(Color botBubbleColor, [String? customText]) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.asset('assets/icons/customer_support.png', width: 28, height: 28)), const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: botBubbleColor, borderRadius: BorderRadius.circular(16)), child: customText != null ? Text(customText, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic)) : AnimatedBuilder(animation: _typingAnimCtrl, builder: (ctx, child) => Row(mainAxisSize: MainAxisSize.min, children: [_buildDot(_dot1), const SizedBox(width: 4), _buildDot(_dot2), const SizedBox(width: 4), _buildDot(_dot3)])))]));
  
  Widget _buildDot(Animation<double> anim) => AnimatedBuilder(animation: anim, builder: (ctx, child) { final offset = anim.value * 4; return Transform.translate(offset: Offset(0, offset), child: Container(width: 7, height: 7, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3 + ((anim.value.abs()) * 0.7)), shape: BoxShape.circle))); });
}
