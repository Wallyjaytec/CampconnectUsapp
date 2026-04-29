import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'my_wallet_view.dart';

class WebPayView extends StatefulWidget {
  const WebPayView({
    super.key,
    required this.initialUrl,
    this.headers = const {},
    this.successUrlContains,
    this.cancelUrlContains,
    this.failedUrlContains,
    this.timeout = const Duration(seconds: 200),
  });

  final String initialUrl;
  final Map<String, String> headers;
  final String? successUrlContains;
  final String? cancelUrlContains;
  final String? failedUrlContains;
  final Duration timeout;

  @override
  State<WebPayView> createState() => _WebPayViewState();
}

class _WebPayViewState extends State<WebPayView> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _completed = false;
  bool _inGrace = true;
  int _navSeq = 0;
  Timer? _hardTimeoutTimer;
  Timer? _graceTimer;
  Timer? _navigationTimer;
  static const Duration _autoRedirectDelay = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (_completed) return;

            _loading = true;
            _navSeq++;
            setState(() {});
          },
          onPageFinished: (url) async {
            if (!_completed) {
              await _controller.runJavaScript(
                "document.body.style.display='none';",
              );
            }
            _loading = true;
            setState(() {});

            if (_completed) return;

            final handledByUrl = _maybeHandleFromUrl(url);
            if (handledByUrl) return;

            await _probeInlineJsonAndCloseIfAny();
            if (_completed) return;

            _showPageContent();
            _scheduleIdleHtmlErrorDetect();
          },
          onNavigationRequest: (req) {
            if (_completed) return NavigationDecision.prevent;

            _navSeq++;
            if (_maybeHandleFromUrl(req.url)) {
              _controller.runJavaScript("document.body.style.display='none';");
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onHttpError: (HttpResponseError err) async {
            if (_completed) return;
            final code = err.response?.statusCode ?? 0;
            if (code >= 400) {
              await _closeWithErrorUI(
                title: (code == 404) ? 'Page not found' : 'Payment Failed',
                subtitle: 'Error: HTTP $code',
                note: 'Payment Unsuccessful. Please wait… Redirecting',
                forceLoadHtml: true,
                delay: _autoRedirectDelay,
              );
            }
          },
          onWebResourceError: (err) async {
            if (_completed) return;
            final isMainFrame = err.isForMainFrame ?? true;
            if (!isMainFrame) return;

            await _closeWithErrorUI(
              title: 'Network Error',
              subtitle: (err.description.isNotEmpty
                  ? err.description
                  : 'Unable to load payment page'),
              note: 'Payment Unsuccessful. Please wait… Redirecting',
              forceLoadHtml: true,
              delay: _autoRedirectDelay,
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl), headers: widget.headers);

    _graceTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _inGrace = false);
    });

    _hardTimeoutTimer = Timer(widget.timeout, () async {
      if (!_completed && mounted) {
        await _closeWithErrorUI(
          title: 'Timed out',
          subtitle: 'Payment page did not respond',
          note: 'Payment Unsuccessful. Please wait… Redirecting',
          forceLoadHtml: true,
          delay: _autoRedirectDelay,
        );
      }
    });
  }

  @override
  void dispose() {
    _hardTimeoutTimer?.cancel();
    _graceTimer?.cancel();
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _showPageContent() {
    if (!_completed) {
      _controller.runJavaScript("document.body.style.display='';");
      _loading = false;
      if (mounted) setState(() {});
    }
  }

  bool _maybeHandleFromUrl(String url) {
    if (_completed) return true;
    final u = url.toLowerCase();

    if (widget.successUrlContains != null &&
        u.contains(widget.successUrlContains!.toLowerCase())) {
      _finishWithStatus(true, 'SUCCESS');
      return true;
    }
    if (widget.cancelUrlContains != null &&
        u.contains(widget.cancelUrlContains!.toLowerCase())) {
      _closeWithErrorUI(
        title: 'Payment Cancelled',
        subtitle: 'The transaction was cancelled by user or system',
        note: 'Payment Unsuccessful. Please wait… Redirecting',
        delay: _autoRedirectDelay,
      );
      return true;
    }
    if (widget.failedUrlContains != null &&
        u.contains(widget.failedUrlContains!.toLowerCase())) {
      _closeWithErrorUI(
        title: 'Payment Failed',
        subtitle: 'The transaction could not be processed',
        note: 'Payment Unsuccessful. Please wait… Redirecting',
        delay: _autoRedirectDelay,
      );
      return true;
    }
    return false;
  }

  Future<void> _probeInlineJsonAndCloseIfAny() async {
    if (_completed) return;

    const js = r'''
(() => {
  const pickText = () => {
    const pre = document.querySelector('pre');
    if (pre && pre.innerText && pre.innerText.trim().length) return pre.innerText.trim();
    const code = document.querySelector('code');
    if (code && code.innerText && code.innerText.trim().length) return code.innerText.trim();
    if (document.body && document.body.innerText) return document.body.innerText.trim();
    return '';
  };
  const t = pickText();
  try {
    const lines = t.split('\n').map(s => s.trim()).filter(Boolean);
    for (const line of lines) {
      try {
        const obj = JSON.parse(line);
        return JSON.stringify(obj);
      } catch (_) {}
    }
    const obj = JSON.parse(t);
    return JSON.stringify(obj);
  } catch (e) {
    return '';
  }
})();
''';

    try {
      final res = await _controller.runJavaScriptReturningResult(js);
      String jsonStr = (res is String) ? res : res.toString();

      if (jsonStr.startsWith('"') && jsonStr.endsWith('"')) {
        jsonStr = jsonDecode(jsonStr) as String;
      }
      if (jsonStr.isEmpty) return;

      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        final success =
            decoded['success'] == true ||
            decoded['success']?.toString().toLowerCase() == 'true';
        final status = (decoded['payment_status'] ?? '')
            .toString()
            .toUpperCase();
        final msg = (decoded['message'] ?? '').toString();

        if (success && status == 'SUCCESS') {
          _finishWithStatus(true, 'SUCCESS');
        } else if (status == 'FAILED' || status == 'CANCELLED') {
          await _closeWithErrorUI(
            title: status == 'FAILED' ? 'Payment Failed' : 'Payment Cancelled',
            subtitle: (msg.isNotEmpty
                ? msg
                : 'The transaction could not be completed'),
            note: 'Payment Unsuccessful. Please wait… Redirecting',
            delay: _autoRedirectDelay,
          );
        } else if (!success) {
          await _closeWithErrorUI(
            title: 'Payment Error',
            subtitle: (msg.isNotEmpty ? msg : 'Something went wrong'),
            note: 'Payment Unsuccessful. Please wait… Redirecting',
            delay: _autoRedirectDelay,
          );
        } else {
          await _closeWithErrorUI(
            title: 'Payment Status Unknown',
            subtitle: 'We could not verify the payment state',
            note: 'Payment Unsuccessful. Please wait… Redirecting',
            delay: _autoRedirectDelay,
          );
        }
      }
    } catch (_) {}
  }

  void _scheduleIdleHtmlErrorDetect() {
    final int seqAtSchedule = _navSeq;
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted || _completed) return;
      if (seqAtSchedule != _navSeq) return;
      if (_loading) return;
      if (_inGrace) return;

      await _detectHtmlErrorAndCloseIfAny();
    });
  }

  Future<void> _detectHtmlErrorAndCloseIfAny() async {
    if (_completed) return;

    const jsDetect = r'''
(function(){
  try{
    const t = (document.title || '').toLowerCase();
    const b = (document.body && document.body.innerText || '').trim().toLowerCase();
    const tooShort = b.length > 0 && b.length < 20;

    function hasAny(s, arr){ return arr.some(x => s.includes(x)); }
    const cues = [' 404 ', 'not found', 'error 404', ' 500 ', 'internal server error', 'bad gateway', 'service unavailable', 'forbidden', 'access denied'];
    if (tooShort || hasAny(' ' + t + ' ', cues) || hasAny(' ' + b + ' ', cues)) {
      return 'ERROR_PAGE';
    }
    return '';
  }catch(e){ return ''; }
})();
''';

    try {
      final r = await _controller.runJavaScriptReturningResult(jsDetect);
      final s = (r is String) ? r : r.toString();
      if (s.contains('ERROR_PAGE')) {
        await _closeWithErrorUI(
          title: 'Page not available',
          subtitle: 'The payment page returned an error',
          note: 'Payment Unsuccessful. Please wait… Redirecting',
          forceLoadHtml: true,
          delay: _autoRedirectDelay,
        );
      }
    } catch (_) {}
  }

  void _finishWithStatus(bool ok, String status) async {
    if (_completed || !mounted) return;

    if (!ok) {
      await _closeWithErrorUI(
        title: (status == 'CANCELLED') ? 'Payment Cancelled' : 'Payment Failed',
        subtitle: 'The transaction could not be completed',
        note: 'Payment Unsuccessful. Please wait… Redirecting',
        delay: _autoRedirectDelay,
      );
      return;
    }

    _completed = true;
    _hardTimeoutTimer?.cancel();
    _graceTimer?.cancel();
    _navigationTimer?.cancel();

    await _showInlineRedirectPage(
      title: 'Thank you',
      subtitle: 'Payment Successful',
      note: 'Please wait… Redirecting',
    );

    _navigationTimer = Timer(_autoRedirectDelay, () {
      if (mounted) {
        _navigateToMyWallet();
      }
    });
  }

  Future<void> _closeWithErrorUI({
    String title = 'Something went wrong',
    String subtitle = 'Unable to complete payment',
    String note = 'Please wait… Redirecting',
    required Duration delay,
    bool forceLoadHtml = false,
  }) async {
    if (_completed || !mounted) return;

    _completed = true;
    _hardTimeoutTimer?.cancel();
    _graceTimer?.cancel();
    _navigationTimer?.cancel();

    await _showInlineRedirectPage(
      title: title,
      subtitle: subtitle,
      note: note,
      useLoadHtmlString: forceLoadHtml,
    );

    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _navigationTimer = Timer(delay, () {
      if (mounted) {
        _navigateToMyWallet();
      }
    });
  }

  Future<void> _showInlineRedirectPage({
    String title = 'Thank you',
    String subtitle = 'Payment complete',
    String note = 'Please wait… Redirecting',
    String? brandLogoUrl,
    bool useLoadHtmlString = false,
  }) async {
    final docHtml =
        '''
<!doctype html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$title</title>
<style>
  body{margin:0;background:#fff;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#111;}
  .wrap{min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px;box-sizing:border-box;}
  .card{width:100%;max-width:560px;border-radius:16px;box-shadow:0 10px 30px rgba(0,0,0,.08);padding:28px 24px;text-align:center;background:#fff;border:1px solid rgba(0,0,0,.06);}
  .logo{width:56px;height:56px;border-radius:12px;margin:0 auto 12px auto;object-fit:contain}
  h1{font-size:20px;margin:4px 0 6px;}
  p{margin:0;opacity:.75;}
  .note{margin-top:12px;font-size:14px;opacity:.85;}
  .spinner{width:22px;height:22px;margin:18px auto 0 auto;border-radius:50%;border:3px solid rgba(0,0,0,.12);border-top-color:rgba(0,0,0,.65);animation:spin .9s linear infinite;}
  @keyframes spin{to{transform:rotate(360deg)}}
</style>
</head>
<body>
<div class="wrap">
  <div class="card">
    ${brandLogoUrl != null && brandLogoUrl.trim().isNotEmpty ? '<img class="logo" src="$brandLogoUrl" />' : ''}
    <h1>$title</h1>
    <p>$subtitle</p>
    <p class="note">$note</p>
    <div class="spinner"></div>
  </div>
</div>
</body>
</html>
''';

    if (useLoadHtmlString) {
      try {
        await _controller.loadHtmlString(docHtml);
        if (mounted) setState(() => _loading = false);
      } catch (_) {}
      return;
    }

    final js =
        '''
(function(){
  try{
    document.head.innerHTML = '';
    document.body.innerHTML = '';
    document.body.style.margin = '0';
    document.body.style.background = '#ffffff';
    document.body.style.fontFamily = '-apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif';
    document.body.style.color = '#111';
    document.body.style.display = 'block';
    const container = document.createElement('div');
    container.innerHTML = ${jsonEncode(docHtml)};
    document.documentElement.innerHTML = container.innerHTML;
  }catch(e){}
})();
''';
    try {
      await _controller.runJavaScript(js);
      if (mounted) setState(() => _loading = false);
    } catch (_) {}
  }

  void _navigateToMyWallet() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MyWalletView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Complete Payment'.tr),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                if (!_completed) {
                  Navigator.of(context).pop(false);
                }
              },
            ),
          ],
          bottom: _loading
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(3),
                  child: LinearProgressIndicator(minHeight: 3),
                )
              : null,
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (!_completed && (_loading || _inGrace))
              Positioned.fill(child: Container(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
