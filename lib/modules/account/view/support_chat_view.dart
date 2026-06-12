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
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' hide ImageSource;
import 'package:image_picker/image_picker.dart';
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
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isLoading = false;
  bool _isTyping = false;
  bool _chatEnded = false;
  bool _showSuggestions = true;
  bool _agentConnected = false;
  bool _waitingForAgent = false;
  String? _agentName;
  DateTime? _chatStartTime;
  String? _chatId;
  Timer? _timer;
  Timer? _typingDelayTimer;
  Timer? _agentPollTimer;
  Timer? _reassureTimer;
  int _reassureCount = 0;
  int? _copyVisibleIndex;

  // Recording
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  late AnimationController _typingAnimCtrl;
  late Animation<double> _dot1, _dot2, _dot3;

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
      return ctrl.pickedImagePath.value.isNotEmpty || ctrl.avatarUrl.value.isNotEmpty;
    } catch (_) {}
    return false;
  }

  String get _userFullName {
    try {
      final ctrl = Get.find<CustomerBasicInfoController>();
      final n = ctrl.name.value.trim();
      return n.isNotEmpty ? n : 'You'.tr;
    } catch (_) {}
    return 'You'.tr;
  }

  String get _firstName {
    try {
      final ctrl = Get.find<CustomerBasicInfoController>();
      final n = ctrl.name.value.trim();
      return n.isNotEmpty ? n.split(' ').first : '';
    } catch (_) {}
    return '';
  }

  String get _recordTimeText {
    final m = (_recordSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_recordSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
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
    } else if (args is List && args.isNotEmpty && args.first is Map) {
      final msgs = args.cast<Map<String, dynamic>>();
      _showSuggestions = false;
      for (final m in msgs) { _history.add({'role': m['role'], 'content': m['text']}); }
      if (msgs.isNotEmpty && msgs.last['role'] == 'user') {
        WidgetsBinding.instance.addPostFrameCallback((_) => _sendMessage(prefill: msgs.last['text']));
      }
    }

    if (_chatId == null) { _chatStartTime = DateTime.now(); _chatId = _chatStartTime!.millisecondsSinceEpoch.toString(); }
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) { _scrollToBottom(); if (_messages.isEmpty) _sendWelcomeMessage(); });
    _loadFromServer();
  }

  @override void didChangePlatformBrightness() { if (mounted) setState(() {}); }

  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) { _stopTypingAnimation(); _saveChat(); _syncToServer(); }
  }

  @override void dispose() {
    _stopAgentPolling(); _stopTypingAnimation(); _stopReassureTimer(); _stopRecordTimer();
    _saveChat(); _syncToServer();
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel(); _typingDelayTimer?.cancel();
    _typingAnimCtrl.dispose(); _audioPlayer.dispose();
    _msgCtrl.dispose(); _scrollCtrl.dispose();
    super.dispose();
  }

  void _startTimer() { _timer = Timer.periodic(const Duration(seconds: 30), (_) { if (mounted) setState(() {}); }); }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  void _startTypingAnimation() { _typingAnimCtrl.repeat(); try { _audioPlayer.stop(); _audioPlayer.play(AssetSource('sounds/typing_sound.m4a')); _audioPlayer.setReleaseMode(ReleaseMode.loop); } catch (_) {} }
  void _stopTypingAnimation() { _typingAnimCtrl.stop(); _typingAnimCtrl.reset(); try { _audioPlayer.stop(); } catch (_) {} }

  void _cancelRequest() { setState(() { _stopTypingAnimation(); _isTyping = false; _isLoading = false; }); _typingDelayTimer?.cancel(); }

  // ─── AGENT POLLING ───────────────────────────────────
  void _startAgentPolling() {
    _agentConnected = true;
    _waitingForAgent = true;
    _reassureCount = 0;
    _agentPollTimer?.cancel();
    _agentPollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollAgentReplies());
    _pollAgentReplies();
    _startReassureTimer();
  }

  void _stopAgentPolling() {
    _agentPollTimer?.cancel();
    _agentConnected = false;
    _waitingForAgent = false;
    _agentName = null;
    _stopReassureTimer();
  }

  void _startReassureTimer() {
    _stopReassureTimer();
    _reassureTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (!mounted || !_waitingForAgent || _chatEnded) return;
      _reassureCount++;
      if (_reassureCount >= 4) {
        setState(() {
          _chatEnded = true;
          _waitingForAgent = false;
          _agentConnected = false;
          _messages.add({'role': 'system', 'text': 'All our agents are busy. Chat closed. Please request a new conversation.'.tr, 'time': DateTime.now(), 'type': 'system_end'});
        });
        _stopAgentPolling();
        _saveChat();
        return;
      }
      setState(() {
        _messages.add({'role': 'system', 'text': 'Still waiting for an agent. Please hold on.'.tr, 'time': DateTime.now(), 'type': 'system_reassure'});
      });
      _scrollToBottom(); _saveChat();
    });
  }

  void _stopReassureTimer() { _reassureTimer?.cancel(); _reassureTimer = null; }

  Future<void> _pollAgentReplies() async {
    try {
      final token = LoginService().token; if (token == null || token.isEmpty) return;
      final resp = await http.post(Uri.parse(AppConfig.agentPollRepliesUrl()), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'});
      final data = jsonDecode(resp.body);
      if (data['success'] != true || data['replies'] == null) return;
      for (final r in (data['replies'] as List)) {
        final txt = r['message']?.toString() ?? '';
        final aName = r['agent_name']?.toString() ?? 'Agent';
        final type = r['type']?.toString() ?? 'text';
        final url = r['media_url']?.toString() ?? '';
        final t = DateTime.tryParse(r['time']?.toString() ?? '') ?? DateTime.now();

        if (txt.startsWith('__AGENT_JOINED__')) {
          final name = txt.replaceAll('__AGENT_JOINED__', '');
          setState(() { _agentName = name; _waitingForAgent = false; _stopReassureTimer(); });
          _addSystemMsg('${'Agent'.tr} $name ${'has joined'.tr}');
          continue;
        }
        if (txt.contains('chat session has been ended')) {
          setState(() => _chatEnded = true);
          _addSystemMsg(txt);
          _stopAgentPolling(); _saveChat(); return;
        }
        setState(() {
          if (type == 'image') _messages.add({'role': 'agent', 'text': url, 'agentName': aName, 'time': t, 'type': 'image'});
          else if (type == 'voice') _messages.add({'role': 'agent', 'text': url, 'agentName': aName, 'time': t, 'type': 'voice'});
          else if (type == 'file') _messages.add({'role': 'agent', 'text': txt, 'agentName': aName, 'time': t, 'type': 'file'});
          else _messages.add({'role': 'agent', 'text': txt, 'agentName': aName, 'time': t, 'type': 'text'});
        });
      }
      _scrollToBottom(); _saveChat();
    } catch (_) {}
  }

  void _addSystemMsg(String text) {
    setState(() => _messages.add({'role': 'system', 'text': text, 'time': DateTime.now(), 'type': 'system_msg'}));
  }

  // ─── RECORDING ───────────────────────────────────────
  void _startRecording() {
    setState(() { _isRecording = true; _isPaused = false; _recordSeconds = 0; });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) { if (!_isPaused && mounted) setState(() => _recordSeconds++); });
  }

  void _pauseResumeRecording() {
    setState(() => _isPaused = !_isPaused);
  }

  void _cancelRecording() {
    _stopRecordTimer();
    setState(() { _isRecording = false; _isPaused = false; _recordSeconds = 0; });
  }

  void _sendRecording() {
    final sec = _recordSeconds;
    _stopRecordTimer();
    setState(() { _isRecording = false; _isPaused = false; _recordSeconds = 0; });
    _messages.add({'role': 'user', 'text': '$_recordTimeText', 'time': DateTime.now(), 'type': 'voice', 'duration': sec});
    _saveChat(); _scrollToBottom();
    // TODO: actually upload voice file
  }

  void _stopRecordTimer() { _recordTimer?.cancel(); _recordTimer = null; }

  void _toggleRecording() {
    if (!_agentConnected) {
      _showSnack('Voice messaging is available when connected to an agent.'.tr);
      return;
    }
    if (_isRecording) { _cancelRecording(); } else { _startRecording(); }
  }

  // ─── SEND MESSAGE ────────────────────────────────────
  void _sendWelcomeMessage() {
    final name = _firstName;
    final g = name.isNotEmpty
        ? '${'Hello'.tr} $name, ${'I\'m Luca, your CampConnectUs Virtual Assistant. Just pick a topic or feel free to type your question.'.tr}'
        : '${'Hello'.tr}! ${'I\'m Luca, your CampConnectUs Virtual Assistant. Just pick a topic or feel free to type your question.'.tr}';
    setState(() { _messages.add({'role': 'bot', 'text': g, 'time': DateTime.now(), 'type': 'text'}); _history.add({'role': 'assistant', 'content': g}); });
    _scrollToBottom(); _saveChat();
  }

  Future<void> _sendMessage({String? prefill, String? imagePath}) async {
    final txt = imagePath != null ? '' : (prefill ?? _msgCtrl.text.trim()).tr;
    if ((txt.isEmpty && imagePath == null) || _isLoading || _chatEnded) return;

    if (imagePath != null) {
      setState(() => _messages.add({'role': 'user', 'text': imagePath, 'time': DateTime.now(), 'type': 'image'}));
    } else {
      setState(() { _showSuggestions = false; _messages.add({'role': 'user', 'text': txt, 'time': DateTime.now(), 'type': 'text'}); _history.add({'role': 'user', 'content': txt}); });
    }
    if (prefill == null && imagePath == null) _msgCtrl.clear();
    _scrollToBottom();

    // If agent is active, forward to agent silently
    if (_agentConnected && !_waitingForAgent) {
      setState(() => _isLoading = true);
      try {
        String? token; for (int i = 0; i < 5; i++) { token = LoginService().token; if (token != null && token.isNotEmpty) break; await Future.delayed(const Duration(milliseconds: 500)); }
        final uri = Uri.parse(AppConfig.chatbotChatUrl());
        if (imagePath != null) {
          var req = http.MultipartRequest('POST', uri); req.headers['Authorization'] = 'Bearer ${token ?? ''}'; req.files.add(await http.MultipartFile.fromPath('image', imagePath)); await req.send().timeout(const Duration(seconds: 35));
        } else {
          await http.post(uri, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${token ?? ''}'}, body: jsonEncode({'message': txt})).timeout(const Duration(seconds: 35));
        }
      } catch (_) {}
      if (mounted) setState(() => _isLoading = false);
      _saveChat();
      return;
    }

    // Normal GPT flow
    setState(() { _isLoading = true; _isTyping = true; });
    _startTypingAnimation(); _scrollToBottom();
    final completer = Completer<void>();
    _typingDelayTimer = Timer(const Duration(seconds: 6), () => completer.complete());
    await completer.future;
    if (!mounted || !_isLoading) return;
    try {
      String? token; for (int i = 0; i < 5; i++) { token = LoginService().token; if (token != null && token.isNotEmpty) break; await Future.delayed(const Duration(milliseconds: 500)); }
      final resp = await http.post(Uri.parse(AppConfig.chatbotChatUrl()), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${token ?? ''}'}, body: jsonEncode({'message': txt, 'history': _history.sublist(0, max(0, _history.length - 1))})).timeout(const Duration(seconds: 35));
      if (!mounted || !_isLoading) return;
      if (resp.statusCode == 200) {
        final d = jsonDecode(resp.body);
        if (d['success'] == true) {
          setState(() { _stopTypingAnimation(); _isTyping = false;
            final reply = d['reply']?.toString() ?? '';
            if (reply.isNotEmpty) { _messages.add({'role': 'bot', 'text': reply, 'time': DateTime.now(), 'type': 'text'}); _history.add({'role': 'assistant', 'content': reply}); }
            if (d['action'] == 'agent_connected') _startAgentPolling();
          });
        } else { _showError(); }
      } else { _showError(); }
    } catch (_) { _showError(); }
    if (mounted) { setState(() => _isLoading = false); _scrollToBottom(); _saveChat(); }
  }

  Future<void> _pickImage() async {
    try { final XFile? img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80); if (img != null) await _sendMessage(imagePath: img.path); } catch (_) {}
  }
  Future<void> _takePhoto() async {
    try { final XFile? img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80); if (img != null) await _sendMessage(imagePath: img.path); } catch (_) {}
  }

  void _showSnack(String msg) {
    if (Get.context != null) ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.primaryColor, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
  }

  void _showAttachSheet() {
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Iconsax.camera, color: AppColors.primaryColor), title: Text('Take a photo'.tr), onTap: () { Navigator.pop(ctx); _takePhoto(); }),
      ListTile(leading: const Icon(Iconsax.gallery, color: AppColors.primaryColor), title: Text('Upload from gallery'.tr), onTap: () { Navigator.pop(ctx); _pickImage(); }),
      const SizedBox(height: 12), Center(child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel'.tr))),
    ])));
  }

  String _formatMarkdown(String t) => t.replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (m) => '<b>${m.group(1)}</b>').replaceAll('\n', '<br>');
  void _showError() {
    if (!mounted) return;
    setState(() { _stopTypingAnimation(); _isTyping = false; _messages.add({'role': 'bot', 'text': "We're sorry, unable to reply. Please request an agent or contact us:\n\n📧 support@campconnectus.store\n📞 +2348155763709".tr, 'time': DateTime.now(), 'type': 'text'}); _isLoading = false; });
    _scrollToBottom(); _saveChat();
  }

  void _saveChat() {
    if (_messages.length < 2) return;
    final chats = box.read<List>('support_chats') ?? [];
    chats.removeWhere((c) => c['id'] == _chatId);
    final last = _messages.last['text'].toString();
    chats.add({'id': _chatId, 'last_message': last.length > 50 ? '${last.substring(0, 50)}...' : last, 'time': DateTime.now().toIso8601String(), 'messages': List.from(_messages), 'chat_start': _chatStartTime?.toIso8601String()});
    box.write('support_chats', chats);
    if (chats.isNotEmpty) _syncToServer();
  }

  Future<void> _syncToServer() async {
    try { final token = LoginService().token; if (token == null || token.isEmpty) return; final chats = box.read<List>('support_chats'); if (chats == null || chats.isEmpty) return; await http.post(Uri.parse(AppConfig.chatbotHistoryUrl()), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: jsonEncode({'action': 'save', 'chats': chats})); } catch (_) {}
  }

  Future<void> _loadFromServer() async {
    try { String? token; for (int i = 0; i < 5; i++) { token = LoginService().token; if (token != null && token.isNotEmpty) break; await Future.delayed(const Duration(milliseconds: 500)); } if (token == null || token.isEmpty) return; final resp = await http.post(Uri.parse(AppConfig.chatbotHistoryUrl()), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: jsonEncode({'action': 'load'})); final d = jsonDecode(resp.body); if (d['success'] == true && d['chats'] != null) box.write('support_chats', d['chats']); } catch (_) {}
  }

  String _fmtTime(DateTime dt) { final n = DateTime.now(); if (dt.day == n.day && dt.month == n.month && dt.year == n.year) return DateFormat('h:mm a').format(dt); return DateFormat('dd/MM/yyyy').format(dt); }
  String _fmtHeader(DateTime dt) { final n = DateTime.now(); if (dt.day == n.day && dt.month == n.month && dt.year == n.year) return DateFormat('h:mm a').format(dt); if (n.difference(dt).inDays == 1) return 'Yesterday'.tr; if (n.difference(dt).inDays < 7) return '${n.difference(dt).inDays} ${'days ago'.tr}'; return DateFormat('dd/MM/yyyy').format(dt); }
  void _copyMsg(String t) { HapticFeedback.mediumImpact(); Clipboard.setData(ClipboardData(text: t)); setState(() => _copyVisibleIndex = null); }
  void _dismissCopy() { if (_copyVisibleIndex != null) setState(() => _copyVisibleIndex = null); }

  // ─── BUILD ───────────────────────────────────────────
  @override Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uColor = isDark ? Colors.white : Colors.grey.shade900;
    final bColor = isDark ? Colors.white : Colors.grey.shade900;
    final bBubble = isDark ? Colors.deepOrange.shade300 : Colors.grey.shade200;
    final uBubble = isDark ? AppColors.primaryColor.withValues(alpha: 0.35) : AppColors.primaryColor.withValues(alpha: 0.15);
    final sw = MediaQuery.of(context).size.width;
    final copyCol = isDark ? Colors.white : Colors.black;

    return GestureDetector(onTap: _dismissCopy, child: Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, leadingWidth: 44, leading: const BackIconWidget(), centerTitle: false, titleSpacing: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Virtual Assistant'.tr, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18)),
          if (_agentName != null && !_waitingForAgent) Text('${'Agent'.tr}: $_agentName', style: TextStyle(fontSize: 12, color: AppColors.primaryColor, fontWeight: FontWeight.w600)),
        ]),
      ),
      body: Column(children: [
        Expanded(child: ListView.builder(controller: _scrollCtrl, padding: const EdgeInsets.all(12), itemCount: _messages.length + (_isTyping ? 1 : 0) + 1 + (_showSuggestions && _messages.length == 1 ? 1 : 0), itemBuilder: (ctx, i) {
          if (i == 0 && _chatStartTime != null) return _buildTimeHeader(_chatStartTime!);
          final mi = i - 1;
          if (_showSuggestions && _messages.length == 1 && mi == _messages.length) return _buildSuggestions();
          if (_isTyping && mi == _messages.length + (_showSuggestions && _messages.length == 1 ? 1 : 0)) return _buildTypingBubble(bBubble);
          if (mi >= 0 && mi < _messages.length) {
            final m = _messages[mi]; final role = m['role']?.toString() ?? 'bot';
            if (role == 'system') return _buildSystemMsg(m);
            final isBot = role == 'bot' || role == 'agent';
            final agentN = m['agentName']?.toString();
            final type = m['type']?.toString() ?? 'text';
            final time = m['time'] is DateTime ? m['time'] as DateTime : DateTime.parse(m['time'].toString());
            return _buildBubble(isBot, m['text'], time, uColor, bColor, uBubble: uBubble, bBubble: bBubble, sw: sw, mi: mi, copyCol: copyCol, type: type, agentN: agentN);
          }
          return const SizedBox.shrink();
        })),
        if (_chatEnded) _buildChatEnded(),
        if (!_chatEnded) SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: _isRecording ? _buildRecordingBar(isDark) : _buildInputBar(isDark))),
      ]),
    ));
  }

  Widget _buildChatEnded() => Padding(padding: const EdgeInsets.all(24), child: Column(children: [Text('── ${'Chat Ended'.tr} ──', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade500)), const SizedBox(height: 4), Text('Please start a new conversation.'.tr, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))]));

  Widget _buildSystemMsg(Map m) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greyCol = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(12)), child: Text(m['text'], textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: greyCol, fontWeight: FontWeight.w500)))));
  }

  Widget _buildInputBar(bool isDark) {
    return Row(children: [
      const SizedBox(width: 4),
      Container(decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.grey.shade300)), child: IconButton(icon: Icon(Iconsax.attach_circle, size: 20, color: AppColors.primaryColor), onPressed: () { if (_agentConnected && !_waitingForAgent) { _showAttachSheet(); } else { _showSnack('File sharing available when connected to an agent.'.tr); } })),
      const SizedBox(width: 6),
      Expanded(child: Container(decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.grey.shade300)), child: TextField(controller: _msgCtrl, enabled: !_chatEnded, decoration: InputDecoration(hintText: _chatEnded ? 'Chat ended'.tr : 'Type a message...'.tr, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16)), onSubmitted: (_) => _sendMessage()))),
      const SizedBox(width: 6),
      Container(decoration: BoxDecoration(color: AppColors.primaryColor, borderRadius: BorderRadius.circular(25)), child: IconButton(icon: const Icon(Iconsax.microphone_2, size: 20, color: Colors.white), onPressed: _toggleRecording)),
      const SizedBox(width: 4),
      Container(decoration: BoxDecoration(color: _isLoading ? Colors.orange : AppColors.primaryColor, borderRadius: BorderRadius.circular(25)), child: IconButton(padding: const EdgeInsets.all(8), icon: Icon(_isLoading ? Icons.stop_rounded : Iconsax.send_1_copy, size: 24, color: Colors.white), onPressed: _isLoading ? _cancelRequest : () => _sendMessage())),
    ]);
  }

  Widget _buildRecordingBar(bool isDark) {
    return Row(children: [
      const SizedBox(width: 4),
      Container(decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(25)), child: IconButton(icon: const Icon(Iconsax.trash, size: 20, color: Colors.white), onPressed: _cancelRecording)),
      const SizedBox(width: 6),
      Expanded(child: Container(decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.red.withValues(alpha: 0.3))), padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
        const Icon(Iconsax.microphone_2, size: 20, color: Colors.red),
        const SizedBox(width: 8),
        ...List.generate(8, (i) => Container(margin: const EdgeInsets.symmetric(horizontal: 1), width: 2, height: 8.0 + (_isPaused ? 2 : Random(i).nextDouble() * 14), decoration: BoxDecoration(color: Colors.red.withValues(alpha: _isPaused ? 0.3 : 0.8), borderRadius: BorderRadius.circular(1)))),
        const Spacer(),
        Text(_recordTimeText, style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w600)),
      ]))),
      const SizedBox(width: 6),
      Container(decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(25)), child: IconButton(icon: Icon(_isPaused ? Iconsax.play : Iconsax.pause, size: 20, color: Colors.white), onPressed: _pauseResumeRecording)),
      const SizedBox(width: 4),
      Container(decoration: BoxDecoration(color: AppColors.primaryColor, borderRadius: BorderRadius.circular(25)), child: IconButton(padding: const EdgeInsets.all(8), icon: const Icon(Iconsax.send_1_copy, size: 24, color: Colors.white), onPressed: _sendRecording)),
    ]);
  }

  Widget _buildTimeHeader(DateTime t) => Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(_fmtHeader(t), style: TextStyle(fontSize: 12, color: Colors.grey.shade500))));

  Widget _buildSuggestions() {
    final s = ['How do I track my order?','What is the return policy?','How to request a refund?','How to recharge my wallet?','What payment methods are available?','How to close my account?','How to report a seller?','What shipping methods do you offer?'];
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text('💡 ${'Frequently Asked'.tr}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: s.map((x) => ActionChip(label: Text(x.tr, style: const TextStyle(fontSize: 11)), onPressed: () => _sendMessage(prefill: x.tr), backgroundColor: AppColors.primaryColor.withValues(alpha: 0.08), side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)))).toList()),
    ]));
  }

  Widget _buildBubble(bool isBot, String text, DateTime time, Color uColor, Color bColor, {required Color uBubble, required Color bBubble, required double sw, required int mi, required Color copyCol, String type = 'text', String? agentN}) {
    final name = isBot ? (agentN ?? 'Luca') : _userFullName;
    final fmt = _formatMarkdown(text);
    final showCopy = _copyVisibleIndex == mi;
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (isBot) ...[ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.asset('assets/icons/customer_support.png', width: 28, height: 28)), const SizedBox(width: 6)] else const Expanded(child: SizedBox()),
      Flexible(child: GestureDetector(onLongPressStart: (_) { HapticFeedback.mediumImpact(); setState(() => _copyVisibleIndex = mi); }, child: Container(
        constraints: BoxConstraints(maxWidth: sw * 0.75), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: isBot ? bBubble : uBubble, borderRadius: isBot ? const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(16), bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)) : const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(4), bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))),
        child: Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            if (name.isNotEmpty) Padding(padding: EdgeInsets.only(right: showCopy ? 22 : 0), child: Text(name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: (isBot ? bColor : uColor).withValues(alpha: 0.7)))),
            const SizedBox(height: 2),
            _buildContent(type, text, fmt, isBot, bColor, uColor, sw),
            const SizedBox(height: 2),
            Align(alignment: Alignment.bottomRight, child: Text(_fmtTime(time), style: TextStyle(fontSize: 10, color: Colors.grey.shade500))),
          ]),
          if (showCopy) Positioned(top: 0, right: 0, child: GestureDetector(onTap: () => _copyMsg(text), child: Icon(Iconsax.copy_copy, size: 18, color: copyCol))),
        ]),
      ))),
      if (!isBot) ...[const SizedBox(width: 6), ClipRRect(borderRadius: BorderRadius.circular(20), child: _hasUserAvatar ? Image.network(_userAvatar, width: 28, height: 28, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset('assets/icons/profile.png', width: 28, height: 28)) : Image.asset('assets/icons/profile.png', width: 28, height: 28))],
    ]));
  }

  Widget _buildContent(String type, String text, String fmt, bool isBot, Color bColor, Color uColor, double sw) {
    if (type == 'image') {
      return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(text), width: sw * 0.6, fit: BoxFit.cover, errorBuilder: (_, __, ___) => CachedNetworkImage(imageUrl: text, width: sw * 0.6, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(width: sw * 0.6, height: 150, color: Colors.grey.shade300, child: const Center(child: Icon(Iconsax.gallery_remove, size: 40))))));
    }
    if (type == 'voice') {
      final isUrl = text.startsWith('http');
      final dur = text.contains(':') ? text : (_formatVoiceDuration(0));
      return GestureDetector(onTap: isUrl ? () { try { _audioPlayer.stop(); _audioPlayer.play(UrlSource(text)); } catch (_) {} } : null, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: AppColors.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)), child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isUrl ? Iconsax.play_circle : Iconsax.microphone_2, size: 22, color: AppColors.primaryColor),
        const SizedBox(width: 8),
        ...List.generate(8, (i) => Container(margin: const EdgeInsets.symmetric(horizontal: 1), width: 2.5, height: 6.0 + (Random(i).nextDouble() * 14), decoration: BoxDecoration(color: AppColors.primaryColor.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(1)))),
        const SizedBox(width: 8),
        Text(isUrl ? 'Tap to play'.tr : dur, style: TextStyle(fontSize: 12, color: AppColors.primaryColor, fontWeight: FontWeight.w500)),
      ])));
    }
    if (type == 'file') {
      return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: AppColors.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Iconsax.document, size: 22, color: AppColors.primaryColor), const SizedBox(width: 8), Flexible(child: Text(text.split('\n').first, style: const TextStyle(fontSize: 13, color: AppColors.primaryColor)))]));
    }
    return HtmlWidget(fmt, textStyle: TextStyle(fontSize: 14, color: isBot ? bColor : uColor));
  }

  String _formatVoiceDuration(int s) { final m = s ~/ 60; final sec = s % 60; return '$m:${sec.toString().padLeft(2, '0')}'; }

  Widget _buildTypingBubble(Color bBubble) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.asset('assets/icons/customer_support.png', width: 28, height: 28)), const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: bBubble, borderRadius: BorderRadius.circular(16)), child: AnimatedBuilder(animation: _typingAnimCtrl, builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: [_buildDot(_dot1), const SizedBox(width: 4), _buildDot(_dot2), const SizedBox(width: 4), _buildDot(_dot3)])))]));

  Widget _buildDot(Animation<double> a) => AnimatedBuilder(animation: a, builder: (_, __) { final o = a.value * 4; return Transform.translate(offset: Offset(0, o), child: Container(width: 7, height: 7, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3 + (a.value.abs() * 0.7)), shape: BoxShape.circle))); });
}
