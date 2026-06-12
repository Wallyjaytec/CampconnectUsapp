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
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart' hide ImageSource;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/login_service.dart';
import '../../../core/services/permission_service.dart';
import '../../../shared/widgets/back_icon_widget.dart';
import '../controller/customer_basic_info_controller.dart';

class SupportChatView extends StatefulWidget {
  const SupportChatView({super.key});
  @override State<SupportChatView> createState() => _SupportChatViewState();
}

class _SupportChatViewState extends State<SupportChatView> with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final List<Map<String, String>> _history = [];
  final box = GetStorage();
  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Record _recorder = Record();

  bool _isLoading = false, _isTyping = false, _chatEnded = false, _showSuggestions = true;
  bool _agentConnected = false, _waitingForAgent = false, _agentTyping = false;
  String? _agentName, _agentProfilePic;
  DateTime? _chatStartTime; String? _chatId;
  Timer? _timer, _typingDelayTimer, _agentPollTimer, _reassureTimer, _recordTimer, _agentTypingTimer;
  int _reassureCount = 0, _recordSeconds = 0;
  int? _copyVisibleIndex;
  bool _isRecording = false, _isPaused = false;
  String? _recordedPath;
  List<double> _amplitudes = [];
  StreamSubscription? _ampSub;
  bool _playingVoice = false;
  String? _playingVoiceSource;
  StreamSubscription? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;

  final Map<String, List<double>> _voiceWaveforms = {};
  final Map<String, Duration> _voicePositions = {};
  final Map<String, Duration> _voiceDurations = {};

  bool _wasBackgrounded = false;
  String? _pendingImagePath;

  late AnimationController _typingAnimCtrl;
  late Animation<double> _dot1, _dot2, _dot3;

  String get _userAvatar {
    try { final c = Get.find<CustomerBasicInfoController>(); if (c.pickedImagePath.value.isNotEmpty) return c.pickedImagePath.value; if (c.avatarUrl.value.isNotEmpty) return c.avatarUrl.value; } catch (_) {}
    return '';
  }
  bool get _hasUserAvatar {
    try { final c = Get.find<CustomerBasicInfoController>(); return c.pickedImagePath.value.isNotEmpty || c.avatarUrl.value.isNotEmpty; } catch (_) {}
    return false;
  }
  String get _userFullName {
    try { final n = Get.find<CustomerBasicInfoController>().name.value.trim(); return n.isNotEmpty ? n : 'You'.tr; } catch (_) {}
    return 'You'.tr;
  }
  String get _firstName {
    try { final n = Get.find<CustomerBasicInfoController>().name.value.trim(); return n.isNotEmpty ? n.split(' ').first : ''; } catch (_) {}
    return '';
  }
  String get _recordTimeText {
    final m = (_recordSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_recordSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  List<double> _getWaveform(String url, int count) {
    if (_voiceWaveforms.containsKey(url)) return _voiceWaveforms[url]!;
    final random = Random(url.hashCode);
    final waveform = List.generate(count, (_) => 0.2 + random.nextDouble() * 0.8);
    _voiceWaveforms[url] = waveform;
    return waveform;
  }

  void _generateNewChatId() {
    _chatId = DateTime.now().millisecondsSinceEpoch.toString();
    _chatStartTime = DateTime.now();
  }

  @override void initState() {
    super.initState(); WidgetsBinding.instance.addObserver(this);
    _typingAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _dot1 = Tween<double>(begin: -1.0, end: 1.0).animate(CurvedAnimation(parent: _typingAnimCtrl, curve: const Interval(0.0, 0.33)));
    _dot2 = Tween<double>(begin: -1.0, end: 1.0).animate(CurvedAnimation(parent: _typingAnimCtrl, curve: const Interval(0.33, 0.66)));
    _dot3 = Tween<double>(begin: -1.0, end: 1.0).animate(CurvedAnimation(parent: _typingAnimCtrl, curve: const Interval(0.66, 1.0)));
    _playerStateSub = _audioPlayer.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      if (s == PlayerState.completed) { _playingVoice = false; _playingVoiceSource = null; _voicePositions.clear(); }
      setState(() => _playingVoice = s == PlayerState.playing);
    });
    _positionSub = _audioPlayer.onPositionChanged.listen((pos) {
      if (!mounted || _playingVoiceSource == null) return;
      setState(() => _voicePositions[_playingVoiceSource!] = pos);
    });
    _audioPlayer.onDurationChanged.listen((dur) {
      if (!mounted || _playingVoiceSource == null) return;
      setState(() => _voiceDurations[_playingVoiceSource!] = dur);
    });

    final args = Get.arguments;
    if (args is Map) {
      if (args['messages'] != null) { final msgs = (args['messages'] as List).cast<Map<String, dynamic>>(); _messages.addAll(msgs); _showSuggestions = false; for (final m in msgs) _history.add({'role': m['role'], 'content': m['text']}); }
      _chatId = args['chatId']?.toString(); _chatStartTime = args['chatStartTime'] != null ? DateTime.parse(args['chatStartTime'].toString()) : null;
      if (args['force_new'] == true) { _generateNewChatId(); _messages.clear(); _history.clear(); _chatEnded = false; _agentConnected = false; _agentName = null; _agentProfilePic = null; _waitingForAgent = false; _showSuggestions = true; _stopAgentPolling(); }
    } else if (args is List && args.isNotEmpty && args.first is Map) {
      final msgs = args.cast<Map<String, dynamic>>(); _showSuggestions = false;
      for (final m in msgs) _history.add({'role': m['role'], 'content': m['text']});
      if (msgs.isNotEmpty && msgs.last['role'] == 'user') WidgetsBinding.instance.addPostFrameCallback((_) => _sendMessage(prefill: msgs.last['text']));
    }
    if (_chatId == null) _generateNewChatId();
    _startTimer(); WidgetsBinding.instance.addPostFrameCallback((_) { _scrollToBottom(); if (_messages.isEmpty) _sendWelcomeMessage(); }); _loadFromServer();
  }

  @override void didChangePlatformBrightness() { if (mounted) setState(() {}); }
  @override void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused || s == AppLifecycleState.inactive || s == AppLifecycleState.hidden) { _wasBackgrounded = true; _saveChat(); _syncToServer(); }
    if (s == AppLifecycleState.resumed && _wasBackgrounded) { _wasBackgrounded = false; if (_agentConnected) _pollAgentReplies(); _loadFromServer(); _scrollToBottom(); }
  }
  @override void dispose() {
    _stopAgentPolling(); _stopTypingAnimation(); _stopReassureTimer(); _stopRecordTimer(); _ampSub?.cancel(); _playerStateSub?.cancel(); _positionSub?.cancel();
    _saveChat(); _syncToServer(); WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel(); _typingDelayTimer?.cancel(); _agentTypingTimer?.cancel(); _typingAnimCtrl.dispose(); _audioPlayer.dispose(); _recorder.dispose();
    _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose();
  }

  void _startTimer() { _timer = Timer.periodic(const Duration(seconds: 30), (_) { if (mounted) setState(() {}); }); }
  void _scrollToBottom() { Future.delayed(const Duration(milliseconds: 100), () { if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); }); }
  void _startTypingAnimation() { _typingAnimCtrl.repeat(); try { _audioPlayer.stop(); _audioPlayer.play(AssetSource('sounds/typing_sound.m4a')); _audioPlayer.setReleaseMode(ReleaseMode.loop); } catch (_) {} }
  void _stopTypingAnimation() { _typingAnimCtrl.stop(); _typingAnimCtrl.reset(); try { _audioPlayer.stop(); } catch (_) {} }
  void _cancelRequest() { setState(() { _stopTypingAnimation(); _isTyping = false; _isLoading = false; }); _typingDelayTimer?.cancel(); }

  void _startAgentTyping() {
    _agentTyping = true;
    _startTypingAnimation();
    _agentTypingTimer?.cancel();
    _agentTypingTimer = Timer(const Duration(seconds: 4), () { if (mounted) setState(() { _agentTyping = false; _stopTypingAnimation(); }); });
  }

  void _startAgentPolling() { _agentConnected = true; _waitingForAgent = true; _reassureCount = 0; _agentPollTimer?.cancel(); _agentPollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollAgentReplies()); _pollAgentReplies(); _startReassureTimer(); }
  void _stopAgentPolling() { _agentPollTimer?.cancel(); _agentConnected = false; _waitingForAgent = false; _agentName = null; _agentProfilePic = null; _stopReassureTimer(); }
  void _startReassureTimer() { _stopReassureTimer(); _reassureTimer = Timer.periodic(const Duration(minutes: 5), (_) { if (!mounted || !_waitingForAgent || _chatEnded) return; _reassureCount++; if (_reassureCount >= 4) { setState(() { _chatEnded = true; _waitingForAgent = false; _agentConnected = false; _messages.add({'role': 'system', 'text': 'All our agents are busy. Chat closed. Please request a new conversation.'.tr, 'time': DateTime.now()}); }); _stopAgentPolling(); _saveChat(); return; } setState(() => _messages.add({'role': 'system', 'text': 'Still waiting for an agent. Please hold on.'.tr, 'time': DateTime.now()})); _scrollToBottom(); _saveChat(); }); }
  void _stopReassureTimer() { _reassureTimer?.cancel(); _reassureTimer = null; }

  Future<void> _pollAgentReplies() async {
    try {
      final token = LoginService().token; if (token == null || token.isEmpty) return;
      final resp = await http.post(Uri.parse(AppConfig.agentPollRepliesUrl()), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'});
      if (resp.statusCode != 200) return;
      final d = jsonDecode(resp.body);
      if (d['success'] != true || d['replies'] == null) return;
      for (final r in (d['replies'] as List)) {
        final txt = r['message']?.toString() ?? '', aName = r['agent_name']?.toString() ?? 'Agent', type = r['type']?.toString() ?? 'text', url = r['media_url']?.toString() ?? '', t = DateTime.tryParse(r['time']?.toString() ?? '') ?? DateTime.now();
        if (txt.startsWith('__AGENT_PIC__')) { setState(() => _agentProfilePic = txt.replaceAll('__AGENT_PIC__', '')); continue; }
        if (txt.startsWith('__AGENT_JOINED__')) { final name = txt.replaceAll('__AGENT_JOINED__', ''); setState(() { _agentName = 'Agent $name'; _waitingForAgent = false; _stopReassureTimer(); _messages.add({'role': 'system', 'text': '${'Agent'.tr} $name ${'has joined the conversation'.tr}', 'time': DateTime.now()}); }); _scrollToBottom(); continue; }
        if (txt.contains('Chat session ended')) { setState(() { _chatEnded = true; _messages.add({'role': 'system', 'text': txt, 'time': t}); }); _stopAgentPolling(); _saveChat(); return; }
        if (txt == '__AGENT_TYPING__') { _startAgentTyping(); continue; }
        if (txt.contains('__TOPIC_DELETED__')) { setState(() { _chatEnded = true; _agentConnected = false; _agentName = null; _messages.add({'role': 'system', 'text': 'This conversation was closed. Please start a new conversation.'.tr, 'time': DateTime.now()}); }); _stopAgentPolling(); _saveChat(); return; }
        final mediaUrl = url.isNotEmpty ? url : txt;
        setState(() { if (type == 'image') _messages.add({'role': 'agent', 'text': mediaUrl, 'agentName': aName, 'time': t, 'type': 'image'}); else if (type == 'voice') _messages.add({'role': 'agent', 'text': mediaUrl, 'agentName': aName, 'time': t, 'type': 'voice'}); else if (type == 'file') _messages.add({'role': 'agent', 'text': txt, 'agentName': aName, 'time': t, 'type': 'file'}); else _messages.add({'role': 'agent', 'text': txt, 'agentName': aName, 'time': t, 'type': 'text'}); });
        _scrollToBottom(); _saveChat();
      }
    } catch (_) {}
  }

  void _sendWelcomeMessage() {
    final name = _firstName;
    final g = name.isNotEmpty ? '${'Hello'.tr} $name, ${"I'm Luca, your CampConnectUs Virtual Assistant. Just pick a topic or feel free to type your question.".tr}' : '${'Hello'.tr}! ${"I'm Luca, your CampConnectUs Virtual Assistant. Just pick a topic or feel free to type your question.".tr}';
    setState(() { _messages.add({'role': 'bot', 'text': g, 'time': DateTime.now(), 'type': 'text'}); _history.add({'role': 'assistant', 'content': g}); }); _scrollToBottom(); _saveChat();
  }

  Future<void> _sendMessage({String? prefill, String? imagePath, bool forceNewTopic = false}) async {
    final txt = imagePath != null ? '' : (prefill ?? _msgCtrl.text.trim());
    if ((txt.isEmpty && imagePath == null) || _isLoading || _chatEnded) return;
    if (imagePath != null) _pendingImagePath = imagePath;
    if (imagePath != null) { setState(() => _messages.add({'role': 'user', 'text': imagePath, 'time': DateTime.now(), 'type': 'image'})); }
    else { setState(() { _showSuggestions = false; _messages.add({'role': 'user', 'text': txt, 'time': DateTime.now(), 'type': 'text'}); _history.add({'role': 'user', 'content': txt}); }); }
    if (prefill == null && imagePath == null) _msgCtrl.clear(); _scrollToBottom();

    if (forceNewTopic && _agentConnected) { _generateNewChatId(); _stopAgentPolling(); }

    final hasTopic = _agentConnected && !_waitingForAgent;
    setState(() { _isLoading = true; _isTyping = !hasTopic; });
    if (!hasTopic) _startTypingAnimation(); _scrollToBottom();
    if (!hasTopic) { final c = Completer<void>(); _typingDelayTimer = Timer(const Duration(seconds: 6), () => c.complete()); await c.future; if (!mounted || !_isLoading) return; }

    try {
      String? token; for (int i = 0; i < 5; i++) { token = LoginService().token; if (token != null && token.isNotEmpty) break; await Future.delayed(const Duration(milliseconds: 500)); }
      final uri = Uri.parse(AppConfig.chatbotChatUrl());
      http.Response resp;
      if (imagePath != null) { var req = http.MultipartRequest('POST', uri); req.headers['Authorization'] = 'Bearer ${token ?? ''}'; req.files.add(await http.MultipartFile.fromPath('image', imagePath)); req.fields['message'] = txt; if (forceNewTopic) req.fields['force_new'] = '1'; final streamed = await req.send().timeout(const Duration(seconds: 35)); resp = await http.Response.fromStream(streamed); }
      else { final body = <String, dynamic>{'message': txt, 'history': _history.sublist(0, max(0, _history.length - 1))}; if (forceNewTopic) body['force_new'] = '1'; resp = await http.post(uri, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${token ?? ''}'}, body: jsonEncode(body)).timeout(const Duration(seconds: 35)); }
      if (!mounted || !_isLoading) return;
      if (resp.statusCode == 200) {
        final d = jsonDecode(resp.body);
        if (d['success'] == true) {
          setState(() { _stopTypingAnimation(); _isTyping = false;
            final reply = d['reply']?.toString() ?? '', action = d['action']?.toString(), status = d['agent_status']?.toString();
            if (action == 'agent_connected') {
              if (!_agentConnected) _startAgentPolling();
              if (d['image_url'] != null && _pendingImagePath != null) { final idx = _messages.indexWhere((m) => m['type'] == 'image' && m['text'] == _pendingImagePath); if (idx >= 0) _messages[idx]['text'] = d['image_url']; _pendingImagePath = null; }
              if (d['media_url'] != null && _recordedPath != null) { final idx = _messages.indexWhere((m) => m['type'] == 'voice' && m['text'] == _recordedPath); if (idx >= 0) _messages[idx]['text'] = d['media_url']; }
              if (status == 'pending') _messages.add({'role': 'system', 'text': 'Please hold on, an agent will be with you shortly.'.tr, 'time': DateTime.now()});
              if (status == 'active' && d['agent_name'] != null && _agentName == null) { _agentName = d['agent_name'].toString(); _waitingForAgent = false; _stopReassureTimer(); }
            } else if (reply.isNotEmpty) { _messages.add({'role': 'bot', 'text': reply, 'time': DateTime.now(), 'type': 'text'}); _history.add({'role': 'assistant', 'content': reply}); }
          });
        } else { _showError(); }
      } else { _showError(); }
    } catch (_) { _showError(); }
    if (mounted) { setState(() => _isLoading = false); _scrollToBottom(); _saveChat(); }
  }

  Future<void> _pickImage() async { try { final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80); if (img != null) await _sendMessage(imagePath: img.path); } catch (_) {} }
  Future<void> _takePhoto() async { try { final img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80); if (img != null) await _sendMessage(imagePath: img.path); } catch (_) {} }
  void _showSnack(String m) { if (Get.context != null) ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(content: Text(m), backgroundColor: AppColors.primaryColor, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2))); }
  void _showAttachSheet() { showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(leading: const Icon(Iconsax.camera, color: AppColors.primaryColor), title: Text('Take a photo'.tr), onTap: () { Navigator.pop(ctx); _takePhoto(); }), ListTile(leading: const Icon(Iconsax.gallery, color: AppColors.primaryColor), title: Text('Upload from gallery'.tr), onTap: () { Navigator.pop(ctx); _pickImage(); }), const SizedBox(height: 12), Center(child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel'.tr)))]))); }

  // Recording
  Future<void> _startRecording() async { final hasPerm = await _recorder.hasPermission(); if (!hasPerm) { _showSnack('Microphone permission required.'.tr); return; } final dir = await getTemporaryDirectory(); final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a'; await _recorder.start(path: path, encoder: AudioEncoder.aacLc, bitRate: 128000, samplingRate: 44100); setState(() { _isRecording = true; _isPaused = false; _recordSeconds = 0; _recordedPath = path; _amplitudes = []; }); _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) { if (!_isPaused && mounted) setState(() => _recordSeconds++); }); _ampSub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 50)).listen((amp) { if (!mounted || _isPaused) return; final norm = ((amp.current + 60) / 60).clamp(0.0, 1.0); setState(() { _amplitudes.add(norm); if (_amplitudes.length > 50) _amplitudes.removeAt(0); }); }); }
  Future<void> _pauseResumeRecording() async { if (_isPaused) { await _recorder.resume(); } else { await _recorder.pause(); } setState(() => _isPaused = !_isPaused); }
  Future<void> _cancelRecording() async { _stopRecordTimer(); _ampSub?.cancel(); if (await _recorder.isRecording()) await _recorder.stop(); if (_recordedPath != null) { try { File(_recordedPath!).deleteSync(); } catch (_) {} } setState(() { _isRecording = false; _isPaused = false; _recordSeconds = 0; _recordedPath = null; _amplitudes = []; }); }
  Future<void> _sendRecording() async { _stopRecordTimer(); _ampSub?.cancel(); final path = _recordedPath; if (path != null && await _recorder.isRecording()) await _recorder.stop(); final durText = _recordTimeText; final sec = _recordSeconds; setState(() { _isRecording = false; _isPaused = false; _recordSeconds = 0; _recordedPath = null; _amplitudes = []; }); if (path == null) return; final waveform = List<double>.from(_amplitudes); while (waveform.length < 30) waveform.add(0.1); _voiceWaveforms[path] = waveform; setState(() => _messages.add({'role': 'user', 'text': path, 'time': DateTime.now(), 'type': 'voice', 'durationText': durText, 'duration': sec})); _saveChat(); _scrollToBottom(); try { String? token; for (int i = 0; i < 5; i++) { token = LoginService().token; if (token != null && token.isNotEmpty) break; await Future.delayed(const Duration(milliseconds: 500)); } var req = http.MultipartRequest('POST', Uri.parse(AppConfig.chatbotChatUrl())); req.headers['Authorization'] = 'Bearer ${token ?? ''}'; req.fields['media_type'] = 'voice'; req.files.add(await http.MultipartFile.fromPath('media', path)); final streamed = await req.send().timeout(const Duration(seconds: 35)); final resp = await http.Response.fromStream(streamed); if (resp.statusCode == 200) { final d = jsonDecode(resp.body); if (d['media_url'] != null) { final newUrl = d['media_url'].toString(); final oldWaveform = _voiceWaveforms[path]; final idx = _messages.indexWhere((m) => m['type'] == 'voice' && m['text'] == path); if (idx >= 0) setState(() => _messages[idx]['text'] = newUrl); if (oldWaveform != null) { _voiceWaveforms.remove(path); _voiceWaveforms[newUrl] = oldWaveform; } } } } catch (_) {} }
  void _stopRecordTimer() { _recordTimer?.cancel(); _recordTimer = null; }
  void _toggleRecording() { if (!_agentConnected || _waitingForAgent) { _showSnack('Voice messaging is available when connected to an agent.'.tr); return; } if (_isRecording) { _cancelRecording(); } else { _startRecording(); } }

  Future<void> _playPauseVoice(String url, {int? durationSec}) async {
    if (_playingVoice && _playingVoiceSource == url) { await _audioPlayer.pause(); setState(() => _playingVoice = false); return; }
    await _audioPlayer.stop(); _playingVoiceSource = url; _voicePositions.remove(url);
    if (url.startsWith('http')) { await _audioPlayer.play(UrlSource(url)); } else { await _audioPlayer.play(DeviceFileSource(url)); }
    if (durationSec != null) _voiceDurations[url] = Duration(seconds: durationSec);
    setState(() => _playingVoice = true);
  }

  String _formatMarkdown(String t) => t.replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (m) => '<b>${m.group(1)}</b>').replaceAll('\n', '<br>');
  void _showError() { if (!mounted) return; setState(() { _stopTypingAnimation(); _isTyping = false; _messages.add({'role': 'bot', 'text': "We're sorry, unable to reply. Please request an agent or contact us:\n\n📧 support@campconnectus.store\n📞 +2348155763709".tr, 'time': DateTime.now(), 'type': 'text'}); _isLoading = false; }); _scrollToBottom(); _saveChat(); }
  void _saveChat() { if (_messages.length < 2) return; final chats = box.read<List>('support_chats') ?? []; chats.removeWhere((c) => c['id'] == _chatId); final last = _messages.last['text'].toString(); chats.add({'id': _chatId, 'last_message': last.length > 50 ? '${last.substring(0, 50)}...' : last, 'time': DateTime.now().toIso8601String(), 'messages': List.from(_messages), 'chat_start': _chatStartTime?.toIso8601String()}); box.write('support_chats', chats); if (chats.isNotEmpty) _syncToServer(); }
  Future<void> _syncToServer() async { try { final t = LoginService().token; if (t == null || t.isEmpty) return; final chats = box.read<List>('support_chats'); if (chats == null || chats.isEmpty) return; await http.post(Uri.parse(AppConfig.chatbotHistoryUrl()), headers: {'Authorization': 'Bearer $t', 'Content-Type': 'application/json'}, body: jsonEncode({'action': 'save', 'chats': chats})); } catch (_) {} }
  Future<void> _loadFromServer() async { try { String? t; for (int i = 0; i < 5; i++) { t = LoginService().token; if (t != null && t.isNotEmpty) break; await Future.delayed(const Duration(milliseconds: 500)); } if (t == null || t.isEmpty) return; final resp = await http.post(Uri.parse(AppConfig.chatbotHistoryUrl()), headers: {'Authorization': 'Bearer $t', 'Content-Type': 'application/json'}, body: jsonEncode({'action': 'load'})); final d = jsonDecode(resp.body); if (d['success'] == true && d['chats'] != null) box.write('support_chats', d['chats']); } catch (_) {} }
  String _fmtTime(DateTime dt) { final n = DateTime.now(); if (dt.day == n.day && dt.month == n.month && dt.year == n.year) return DateFormat('h:mm a').format(dt); return DateFormat('dd/MM/yyyy').format(dt); }
  String _fmtHeader(DateTime dt) { final n = DateTime.now(); if (dt.day == n.day && dt.month == n.month && dt.year == n.year) return DateFormat('h:mm a').format(dt); if (n.difference(dt).inDays == 1) return 'Yesterday'.tr; if (n.difference(dt).inDays < 7) return '${n.difference(dt).inDays} ${'days ago'.tr}'; return DateFormat('dd/MM/yyyy').format(dt); }
  void _copyMsg(String t) { HapticFeedback.mediumImpact(); Clipboard.setData(ClipboardData(text: t)); setState(() => _copyVisibleIndex = null); }
  void _dismissCopy() { if (_copyVisibleIndex != null) setState(() => _copyVisibleIndex = null); }

  @override Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uColor = isDark ? Colors.white : Colors.grey.shade900, bColor = isDark ? Colors.white : Colors.grey.shade900;
    final bBubble = isDark ? Colors.deepOrange.shade300 : Colors.grey.shade200, uBubble = isDark ? AppColors.primaryColor.withValues(alpha: 0.35) : AppColors.primaryColor.withValues(alpha: 0.15);
    final sw = MediaQuery.of(context).size.width, copyCol = isDark ? Colors.white : Colors.black;

    String statusText;
    if (_isTyping || _agentTyping) { statusText = 'typing...'.tr; }
    else if (_isRecording) { statusText = 'recording...'.tr; }
    else { statusText = 'online'.tr; }

    Widget headerIcon = ClipRRect(borderRadius: BorderRadius.circular(18), child: (_agentProfilePic != null && _agentProfilePic!.isNotEmpty) ? CachedNetworkImage(imageUrl: _agentProfilePic!, width: 36, height: 36, fit: BoxFit.cover, errorWidget: (_, __, ___) => Image.asset('assets/icons/support_header_icon.png', width: 36, height: 36)) : Image.asset('assets/icons/support_header_icon.png', width: 36, height: 36));

    return GestureDetector(onTap: _dismissCopy, child: Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, leadingWidth: 44, leading: const BackIconWidget(), centerTitle: false, titleSpacing: 0,
        title: Row(children: [headerIcon, const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [Flexible(child: Text(_agentName != null ? _agentName! : 'CampConnectU Virtual Assistant'.tr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis)), const SizedBox(width: 4), Image.asset('assets/images/verifybadge.png', width: 14, height: 14)]),
            const SizedBox(height: 1), Text(statusText, style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
          ])),
        ]),
      ),
      body: Column(children: [
        Expanded(child: ListView.builder(controller: _scrollCtrl, padding: const EdgeInsets.all(12), itemCount: _messages.length + (_isTyping || _agentTyping ? 1 : 0) + 1 + (_showSuggestions && _messages.length == 1 ? 1 : 0), itemBuilder: (ctx, i) {
          if (i == 0 && _chatStartTime != null) return _buildTimeHeader(_chatStartTime!);
          final mi = i - 1;
          if (_showSuggestions && _messages.length == 1 && mi == _messages.length) return _buildSuggestions();
          if ((_isTyping || _agentTyping) && mi == _messages.length + (_showSuggestions && _messages.length == 1 ? 1 : 0)) return _buildTypingBubble(bBubble);
          if (mi >= 0 && mi < _messages.length) {
            final m = _messages[mi]; final role = m['role']?.toString() ?? 'bot';
            if (role == 'system') return _buildSystemMsg(m);
            final isBot = role == 'bot' || role == 'agent';
            final agentN = m['agentName']?.toString(), type = m['type']?.toString() ?? 'text';
            final time = m['time'] is DateTime ? m['time'] as DateTime : DateTime.parse(m['time'].toString());
            return _buildBubble(isBot, m, time, uColor, bColor, uBubble: uBubble, bBubble: bBubble, sw: sw, mi: mi, copyCol: copyCol, type: type, agentN: agentN);
          }
          return const SizedBox.shrink();
        })),
        if (_chatEnded) _buildChatEnded(),
        if (!_chatEnded) SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: _isRecording ? _buildRecordingBar(isDark) : _buildInputBar(isDark))),
      ]),
    ));
  }

  Widget _buildChatEnded() => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.grey.shade100), child: Column(children: [const Icon(Iconsax.message_remove, size: 40, color: Colors.grey), const SizedBox(height: 12), Text('Conversation Ended'.tr, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.grey.shade500)), const SizedBox(height: 4), Text('Please start a new conversation.'.tr, style: TextStyle(fontSize: 13, color: Colors.grey.shade500))]));
  Widget _buildSystemMsg(Map m) { final isDark = Theme.of(context).brightness == Brightness.dark; final greyCol = isDark ? Colors.grey.shade400 : Colors.grey.shade600; return Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Center(child: Text(m['text'], textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: greyCol, fontWeight: FontWeight.w500)))); }

  Widget _buildInputBar(bool isDark) => Row(children: [
    const SizedBox(width: 4), Container(decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.grey.shade300)), child: IconButton(icon: Icon(Iconsax.attach_circle, size: 20, color: AppColors.primaryColor), onPressed: () { if (_agentConnected && !_waitingForAgent) { _showAttachSheet(); } else { _showSnack('File sharing available when connected to an agent.'.tr); } })),
    const SizedBox(width: 6), Expanded(child: Container(decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.grey.shade300)), child: TextField(controller: _msgCtrl, enabled: !_chatEnded, decoration: InputDecoration(hintText: _chatEnded ? 'Chat ended'.tr : 'Type a message...'.tr, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16)), onSubmitted: (_) => _sendMessage(), textInputAction: TextInputAction.send))),
    const SizedBox(width: 6), Container(decoration: BoxDecoration(color: AppColors.primaryColor, borderRadius: BorderRadius.circular(25)), child: IconButton(icon: const Icon(Iconsax.microphone_2, size: 20, color: Colors.white), onPressed: _toggleRecording)),
    const SizedBox(width: 4), Container(decoration: BoxDecoration(color: _isLoading ? Colors.orange : AppColors.primaryColor, borderRadius: BorderRadius.circular(25)), child: IconButton(padding: const EdgeInsets.all(8), icon: Icon(_isLoading ? Icons.stop_rounded : Iconsax.send_1_copy, size: 24, color: Colors.white), onPressed: _isLoading ? _cancelRequest : () => _sendMessage())),
  ]);

  Widget _buildRecordingBar(bool isDark) {
    final displayAmps = _amplitudes.isNotEmpty ? List.from(_amplitudes) : List.filled(25, 0.08);
    return Row(children: [
      const SizedBox(width: 4), Container(decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.grey.shade300)), child: IconButton(icon: const Icon(Iconsax.trash, size: 20, color: Colors.red), onPressed: _cancelRecording)),
      const SizedBox(width: 6),
      Expanded(child: Container(height: 52, decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.grey.shade300)), padding: const EdgeInsets.symmetric(horizontal: 14), child: Row(children: [
        _isPaused ? Icon(Iconsax.microphone_slash, size: 20, color: Colors.grey.shade400) : Icon(Iconsax.microphone_2, size: 20, color: Colors.orange),
        const SizedBox(width: 10), Expanded(child: SizedBox(height: 32, child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: displayAmps.take(35).map((a) { final h = 4.0 + (a * 28); return AnimatedContainer(duration: const Duration(milliseconds: 50), margin: const EdgeInsets.symmetric(horizontal: 1), width: 2.5, height: h, decoration: BoxDecoration(color: _isPaused ? Colors.grey.shade400 : Colors.orange.withValues(alpha: 0.5 + a * 0.5), borderRadius: BorderRadius.circular(2))); }).toList()))),
        const SizedBox(width: 10), Text(_recordTimeText, style: TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.w600)),
      ]))),
      const SizedBox(width: 6), Container(decoration: BoxDecoration(color: isDark ? AppColors.darkCardColor : AppColors.lightCardColor, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.grey.shade300)), child: IconButton(icon: Icon(_isPaused ? Iconsax.play : Iconsax.pause, size: 20, color: AppColors.primaryColor), onPressed: _pauseResumeRecording)),
      const SizedBox(width: 4), Container(decoration: BoxDecoration(color: AppColors.primaryColor, borderRadius: BorderRadius.circular(25)), child: IconButton(padding: const EdgeInsets.all(8), icon: const Icon(Iconsax.send_1_copy, size: 24, color: Colors.white), onPressed: _sendRecording)),
    ]);
  }

  Widget _buildTimeHeader(DateTime t) => Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(_fmtHeader(t), style: TextStyle(fontSize: 12, color: Colors.grey.shade500))));
  Widget _buildSuggestions() { final s = ['How do I track my order?','What is the return policy?','How to request a refund?','How to recharge my wallet?','What payment methods are available?','How to close my account?','How to report a seller?','What shipping methods do you offer?']; return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('💡 ${'Frequently Asked'.tr}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)), const SizedBox(height: 8), Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: s.map((x) => ActionChip(label: Text(x.tr, style: const TextStyle(fontSize: 11)), onPressed: () => _sendMessage(prefill: x.tr), backgroundColor: AppColors.primaryColor.withValues(alpha: 0.08), side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)))).toList())])); }

  Widget _buildBubble(bool isBot, Map m, DateTime time, Color uColor, Color bColor, {required Color uBubble, required Color bBubble, required double sw, required int mi, required Color copyCol, String type = 'text', String? agentN}) {
    final name = isBot ? (agentN ?? 'Luca') : _userFullName; final text = m['text']?.toString() ?? ''; final fmt = _formatMarkdown(text); final showCopy = _copyVisibleIndex == mi;
    final canCopy = type == 'text';
    final isAgent = agentN != null && agentN != 'Luca';
    final botIcon = (isAgent && _agentProfilePic != null && _agentProfilePic!.isNotEmpty)
        ? ClipRRect(borderRadius: BorderRadius.circular(20), child: CachedNetworkImage(imageUrl: _agentProfilePic!, width: 28, height: 28, fit: BoxFit.cover, errorWidget: (_, __, ___) => Image.asset('assets/icons/customer_support.png', width: 28, height: 28)))
        : ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.asset('assets/icons/customer_support.png', width: 28, height: 28));
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (isBot) ...[botIcon, const SizedBox(width: 6)] else const Expanded(child: SizedBox()),
      Flexible(child: GestureDetector(onLongPressStart: canCopy ? (_) { HapticFeedback.mediumImpact(); setState(() => _copyVisibleIndex = mi); } : null, child: Container(constraints: BoxConstraints(maxWidth: sw * 0.78), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: isBot ? bBubble : uBubble, borderRadius: isBot ? const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(16), bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)) : const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(4), bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))), child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          if (name.isNotEmpty) Padding(padding: EdgeInsets.only(right: showCopy ? 22 : 0), child: Text(name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: (isBot ? bColor : uColor).withValues(alpha: 0.7)))), const SizedBox(height: 2),
          _buildContent(type, m, fmt, isBot, bColor, uColor, sw), const SizedBox(height: 2),
          Align(alignment: Alignment.bottomRight, child: Text(_fmtTime(time), style: TextStyle(fontSize: 10, color: Colors.grey.shade500))),
        ]),
        if (showCopy) Positioned(top: 0, right: 0, child: GestureDetector(onTap: () => _copyMsg(text), child: Icon(Iconsax.copy_copy, size: 18, color: copyCol))),
      ])))),
      if (!isBot) ...[const SizedBox(width: 6), ClipRRect(borderRadius: BorderRadius.circular(20), child: _hasUserAvatar ? Image.network(_userAvatar, width: 28, height: 28, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset('assets/icons/profile.png', width: 28, height: 28)) : Image.asset('assets/icons/profile.png', width: 28, height: 28))],
    ]));
  }

  Widget _buildContent(String type, Map m, String fmt, bool isBot, Color bColor, Color uColor, double sw) {
    final text = m['text']?.toString() ?? '';
    if (type == 'image') {
      final isLocal = !text.startsWith('http') && !text.startsWith('https');
      Widget img;
      if (isLocal) { final f = File(text); img = f.existsSync() ? Image.file(f, width: sw * 0.6, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildImageError(sw)) : _buildImageError(sw); }
      else { img = CachedNetworkImage(imageUrl: text, width: sw * 0.6, fit: BoxFit.cover, placeholder: (_, __) => Container(width: sw * 0.6, height: 150, color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))), errorWidget: (_, __, ___) => _buildImageError(sw)); }
      return ClipRRect(borderRadius: BorderRadius.circular(8), child: img);
    }
    if (type == 'voice') {
      final isRemote = text.startsWith('http');
      final durLabel = m['durationText']?.toString() ?? '';
      final durSec = m['duration'] as int? ?? 0;
      final isPlaying = _playingVoice && _playingVoiceSource == text;
      final waveform = _getWaveform(text, 20);
      final totalDur = _voiceDurations[text] ?? Duration(seconds: durSec);
      final position = _voicePositions[text] ?? Duration.zero;
      final progress = totalDur.inMilliseconds > 0 ? position.inMilliseconds / totalDur.inMilliseconds : 0.0;
      final filledCount = (waveform.length * progress.clamp(0.0, 1.0)).round();
      final displayDuration = durLabel.isNotEmpty ? durLabel : (totalDur.inSeconds > 0 ? _formatDuration(totalDur) : '');
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        constraints: BoxConstraints(maxWidth: sw * 0.65),
        decoration: BoxDecoration(color: AppColors.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          GestureDetector(onTap: () => _playPauseVoice(text, durationSec: durSec), child: Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.primaryColor.withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(isPlaying ? Iconsax.pause : Iconsax.play, size: 16, color: AppColors.primaryColor))),
          const SizedBox(width: 8),
          Expanded(child: SizedBox(height: 28, child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: waveform.asMap().entries.map((e) { final h = 4.0 + (e.value * 20); final filled = e.key < filledCount; return Container(margin: const EdgeInsets.symmetric(horizontal: 1), width: 2.5, height: h, decoration: BoxDecoration(color: filled ? AppColors.primaryColor.withValues(alpha: 0.85) : AppColors.primaryColor.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(1.5))); }).toList()))),
          if (displayDuration.isNotEmpty) ...[const SizedBox(width: 8), Text(displayDuration, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500))],
        ]),
      );
    }
    if (type == 'file') return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: AppColors.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Iconsax.document, size: 22, color: AppColors.primaryColor), const SizedBox(width: 8), Flexible(child: Text(text.split('\n').first.replaceAll('📎 ', ''), style: const TextStyle(fontSize: 13, color: AppColors.primaryColor)))]));
    return HtmlWidget(fmt, textStyle: TextStyle(fontSize: 14, color: isBot ? bColor : uColor));
  }

  Widget _buildImageError(double sw) => Container(width: sw * 0.6, height: 150, color: Colors.grey.shade300, child: const Center(child: Icon(Iconsax.gallery_remove, size: 40)));
  String _formatDuration(Duration d) { final m = d.inMinutes.toString().padLeft(2, '0'); final s = (d.inSeconds % 60).toString().padLeft(2, '0'); return '$m:$s'; }

  Widget _buildTypingBubble(Color bBubble) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.asset('assets/icons/customer_support.png', width: 28, height: 28)), const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: bBubble, borderRadius: BorderRadius.circular(16)), child: AnimatedBuilder(animation: _typingAnimCtrl, builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: [_buildDot(_dot1), const SizedBox(width: 4), _buildDot(_dot2), const SizedBox(width: 4), _buildDot(_dot3)])))]));
  Widget _buildDot(Animation<double> a) => AnimatedBuilder(animation: a, builder: (_, __) { final o = a.value * 4; return Transform.translate(offset: Offset(0, o), child: Container(width: 7, height: 7, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3 + (a.value.abs()) * 0.7), shape: BoxShape.circle))); });
}
