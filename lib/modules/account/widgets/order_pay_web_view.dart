import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum PaymentPageResultStatus { success, cancelled, failed, error, timeout }

class PaymentPageResult {
  final PaymentPageResultStatus status;
  final String? message;
  final String? finalUrl;

  const PaymentPageResult({required this.status, this.message, this.finalUrl});

  bool get isSuccess => status == PaymentPageResultStatus.success;
}

typedef PaymentStatusChecker = Future<PaymentPageResult?> Function();

class OrderPayWebView extends StatefulWidget {
  const OrderPayWebView({
    super.key,
    required this.initialUrl,
    this.headers = const {},
    this.successUrlContains = const [],
    this.cancelUrlContains = const [],
    this.failedUrlContains = const [],
    this.pendingUrlContains = const [],
    this.timeout = const Duration(minutes: 5),
    this.maxSilentReloads = 1,
    this.silentReloadDelay = const Duration(milliseconds: 1200),
    this.statusChecker,
    this.statusCheckInterval = const Duration(seconds: 2),
    this.statusCheckDuration = const Duration(seconds: 16),
    this.allowManualClose = true,
  });

  final String initialUrl;
  final Map<String, String> headers;
  final List<String> successUrlContains;
  final List<String> cancelUrlContains;
  final List<String> failedUrlContains;
  final List<String> pendingUrlContains;
  final Duration timeout;
  final int maxSilentReloads;
  final Duration silentReloadDelay;
  final PaymentStatusChecker? statusChecker;
  final Duration statusCheckInterval;
  final Duration statusCheckDuration;
  final bool allowManualClose;

  @override
  State<OrderPayWebView> createState() => _OrderPayWebViewState();
}

class _OrderPayWebViewState extends State<OrderPayWebView> {
  late final WebViewController _controller;

  bool _loading = true;
  bool _completed = false;
  bool _bootMaskVisible = true;
  bool _firstStablePageLoaded = false;
  bool _statusPollingStarted = false;
  bool _recovering = false;
  bool _initialLoadDone = false;
  bool _reloadInProgress = false;

  int _navSeq = 0;
  int _silentReloadCount = 0;

  String? _currentUrl;
  String? _lastMainFrameError;
  int? lastHttpCode;

  Timer? _bootMaskTimer;
  Timer? _hardTimeoutTimer;
  Timer? _pendingRecoveryTimer;
  Timer? _statusPollTimer;

  static const Duration _bootMaskDuration = Duration(seconds: 2);
  static const Duration _errorConfirmDelay = Duration(milliseconds: 1400);

  static const List<String> _gatewayDomains = [
    'razorpay.com',
    'paypal.com',
    'stripe.com',
    'sslcommerz.com',
    'paystack.co',
    'paystack.com',
    'checkout.paystack.com',
    'mollie.com',
    'paddle.com',
    'mercadopago.com',
    'paymob.com',
    'gpay.app',
    'checkout.google.com',
  ];

  bool _isOnGatewayDomain([String? url]) {
    final target = (url ?? _currentUrl ?? '').toLowerCase();
    if (target.isEmpty) return false;
    return _gatewayDomains.any((d) => target.contains(d));
  }

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

            _navSeq++;
            _currentUrl = url;
            _loading = true;
            _reloadInProgress = false;
            _clearTransientErrorState();

            if (!_isOnGatewayDomain(url)) {
              _startBootMask();
            }

            if (mounted) setState(() {});
          },
          onPageFinished: (url) async {
            if (_completed) return;

            _currentUrl = url;
            _loading = false;
            _initialLoadDone = true;
            _cancelPendingRecovery();

            if (mounted) setState(() {});

            final matchedFromUrl = _matchUrl(url);
            if (matchedFromUrl != null) {
              _complete(matchedFromUrl, finalUrl: url);
              return;
            }

            final inlineStatus = await _tryReadInlineStatusFromPage();
            if (_completed) return;
            if (inlineStatus != null) {
              _complete(inlineStatus, finalUrl: url);
              return;
            }

            if (_isOnGatewayDomain(url)) {
              _firstStablePageLoaded = true;
              _recovering = false;
              return;
            }

            final htmlLooksBroken = await _pageLooksLikeFatalError();
            if (_completed) return;

            if (!htmlLooksBroken) {
              _firstStablePageLoaded = true;
              _recovering = false;
              return;
            }

            _scheduleRecoverOrFail(
              reason: 'The payment page returned an error.',
            );
          },
          onNavigationRequest: (request) {
            if (_completed) return NavigationDecision.prevent;

            _navSeq++;
            _currentUrl = request.url;

            final matched = _matchUrl(request.url);
            if (matched != null) {
              _complete(matched, finalUrl: request.url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onHttpError: (HttpResponseError error) {
            if (_completed) return;

            final code = error.response?.statusCode ?? 0;
            if (code < 400) return;

            if (!_initialLoadDone) return;
            if (_reloadInProgress) return;
            if (_isOnGatewayDomain()) return;

            lastHttpCode = code;
            _scheduleRecoverOrFail(
              reason: 'HTTP $code while loading payment page.',
            );
          },
          onWebResourceError: (WebResourceError error) {
            if (_completed) return;

            final isMainFrame = error.isForMainFrame ?? true;
            if (!isMainFrame) return;

            if (!_initialLoadDone) return;
            if (_reloadInProgress) return;
            if (_isOnGatewayDomain()) return;

            _lastMainFrameError = error.description.isNotEmpty
                ? error.description
                : 'Unable to load payment page';

            _scheduleRecoverOrFail(reason: _lastMainFrameError!);
          },
        ),
      );

    _startBootMask();
    _startHardTimeout();
    _loadInitialRequestOnce();
  }

  void _loadInitialRequestOnce() {
    final url = widget.initialUrl.trim();
    if (url.isEmpty) return;
    _controller.loadRequest(Uri.parse(url), headers: widget.headers);
  }

  void _startBootMask() {
    _bootMaskTimer?.cancel();
    _bootMaskVisible = true;
    _bootMaskTimer = Timer(_bootMaskDuration, () {
      if (!mounted || _completed) return;
      setState(() => _bootMaskVisible = false);
    });
  }

  void _startHardTimeout() {
    _hardTimeoutTimer?.cancel();
    _hardTimeoutTimer = Timer(widget.timeout, () async {
      if (!mounted || _completed) return;

      final verified = await _tryStatusCheckBeforeFail();
      if (_completed) return;
      if (verified != null) {
        _complete(verified, finalUrl: _currentUrl);
        return;
      }

      _complete(
        const PaymentPageResult(
          status: PaymentPageResultStatus.timeout,
          message: 'Payment page timed out.',
        ),
        finalUrl: _currentUrl,
      );
    });
  }

  PaymentPageResult? _matchUrl(String url) {
    final lower = url.toLowerCase();

    bool hasAny(List<String> patterns) {
      for (final raw in patterns) {
        final p = raw.trim().toLowerCase();
        if (p.isNotEmpty && lower.contains(p)) return true;
      }
      return false;
    }

    if (hasAny(widget.successUrlContains)) {
      return const PaymentPageResult(
        status: PaymentPageResultStatus.success,
        message: 'Payment successful.',
      );
    }
    if (hasAny(widget.cancelUrlContains)) {
      return const PaymentPageResult(
        status: PaymentPageResultStatus.cancelled,
        message: 'Payment cancelled.',
      );
    }
    if (hasAny(widget.failedUrlContains)) {
      return const PaymentPageResult(
        status: PaymentPageResultStatus.failed,
        message: 'Payment failed.',
      );
    }
    if (hasAny(widget.pendingUrlContains)) {
      _startStatusPollingIfNeeded();
      return null;
    }

    return null;
  }

  Future<PaymentPageResult?> _tryReadInlineStatusFromPage() async {
    const js = r'''
(() => {
  try {
    const pickText = () => {
      const pre = document.querySelector('pre');
      if (pre && pre.innerText && pre.innerText.trim()) return pre.innerText.trim();
      const code = document.querySelector('code');
      if (code && code.innerText && code.innerText.trim()) return code.innerText.trim();
      if (document.body && document.body.innerText) return document.body.innerText.trim();
      return '';
    };
    const t = (pickText() || '').trim();
    if (!t) return '';
    const upper = t.toUpperCase();
    if (upper === 'SUCCESS' || upper === 'FAILED' || upper === 'CANCELLED' || upper === 'PENDING') {
      return JSON.stringify({ payment_status: upper, success: upper === 'SUCCESS' });
    }
    const lines = t.split('\n').map(s => s.trim()).filter(Boolean);
    for (const line of lines) {
      try { const obj = JSON.parse(line); return JSON.stringify(obj); } catch (_) {}
    }
    try { const obj = JSON.parse(t); return JSON.stringify(obj); } catch (_) {}
    return '';
  } catch (_) { return ''; }
})();
''';

    try {
      final res = await _controller.runJavaScriptReturningResult(js);
      String jsonStr = (res is String) ? res : res.toString();
      if (jsonStr.startsWith('"') && jsonStr.endsWith('"')) {
        jsonStr = jsonDecode(jsonStr) as String;
      }
      if (jsonStr.isEmpty) return null;

      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) return null;

      final status =
          (decoded['payment_status'] ??
                  decoded['status'] ??
                  decoded['paymentStatus'] ??
                  '')
              .toString()
              .toUpperCase();
      final success =
          decoded['success'] == true ||
          decoded['success']?.toString().toLowerCase() == 'true';

      if (success || status == 'SUCCESS' || status == 'PAID') {
        return const PaymentPageResult(
          status: PaymentPageResultStatus.success,
          message: 'Payment successful.',
        );
      }
      if (status == 'FAILED' || status == 'FAIL' || status == 'ERROR') {
        return const PaymentPageResult(
          status: PaymentPageResultStatus.failed,
          message: 'Payment failed.',
        );
      }
      if (status == 'CANCELLED' || status == 'CANCELED') {
        return const PaymentPageResult(
          status: PaymentPageResultStatus.cancelled,
          message: 'Payment cancelled.',
        );
      }
      if (status == 'PENDING' || status == 'PROCESSING') {
        _startStatusPollingIfNeeded();
      }
    } catch (_) {}

    return null;
  }

  Future<bool> _pageLooksLikeFatalError() async {
    const js = r'''
(function() {
  try {
    const title = (document.title || '').toLowerCase();
    const body = (document.body && document.body.innerText || '').trim().toLowerCase();
    function hasAny(s, arr) { return arr.some(x => s.includes(x)); }
    const cues = [' 404 ','not found','error 404',' 500 ','internal server error',
      'bad gateway','service unavailable','forbidden','access denied','page not found'];
    return hasAny(' ' + title + ' ', cues) || hasAny(' ' + body + ' ', cues);
  } catch (_) { return false; }
})();
''';

    try {
      final res = await _controller.runJavaScriptReturningResult(js);
      return (res is String ? res : res.toString()).contains('true');
    } catch (_) {
      return false;
    }
  }

  void _scheduleRecoverOrFail({required String reason}) {
    if (_reloadInProgress) return;
    if (_isOnGatewayDomain()) return;

    _cancelPendingRecovery();
    final int seqAtError = _navSeq;

    _pendingRecoveryTimer = Timer(_errorConfirmDelay, () async {
      if (!mounted || _completed) return;
      if (seqAtError != _navSeq) return;
      if (_loading) return;
      if (_reloadInProgress) return;
      if (_isOnGatewayDomain()) return;

      final matched = _currentUrl == null ? null : _matchUrl(_currentUrl!);
      if (matched != null) {
        _complete(matched, finalUrl: _currentUrl);
        return;
      }

      final inlineStatus = await _tryReadInlineStatusFromPage();
      if (_completed) return;
      if (inlineStatus != null) {
        _complete(inlineStatus, finalUrl: _currentUrl);
        return;
      }

      final verified = await _tryStatusCheckBeforeFail();
      if (_completed) return;
      if (verified != null) {
        _complete(verified, finalUrl: _currentUrl);
        return;
      }

      if (_firstStablePageLoaded &&
          !_recovering &&
          _silentReloadCount < widget.maxSilentReloads) {
        _recovering = true;
        _reloadInProgress = true;
        _silentReloadCount++;

        await Future.delayed(widget.silentReloadDelay);
        if (!mounted || _completed) return;

        _startBootMask();
        _loading = true;
        if (mounted) setState(() {});

        await _controller.reload();
        return;
      }

      _complete(
        PaymentPageResult(
          status: PaymentPageResultStatus.error,
          message: reason,
        ),
        finalUrl: _currentUrl,
      );
    });
  }

  void _startStatusPollingIfNeeded() {
    if (_completed || _statusPollingStarted || widget.statusChecker == null) {
      return;
    }

    _statusPollingStarted = true;
    final startedAt = DateTime.now();

    _statusPollTimer = Timer.periodic(widget.statusCheckInterval, (
      timer,
    ) async {
      if (!mounted || _completed) {
        timer.cancel();
        return;
      }
      if (DateTime.now().difference(startedAt) > widget.statusCheckDuration) {
        timer.cancel();
        return;
      }
      try {
        final result = await widget.statusChecker!.call();
        if (result == null || _completed) return;
        if (result.status == PaymentPageResultStatus.success ||
            result.status == PaymentPageResultStatus.cancelled ||
            result.status == PaymentPageResultStatus.failed) {
          timer.cancel();
          _complete(result, finalUrl: _currentUrl);
        }
      } catch (_) {}
    });
  }

  Future<PaymentPageResult?> _tryStatusCheckBeforeFail() async {
    if (widget.statusChecker == null) return null;
    try {
      final result = await widget.statusChecker!.call();
      if (result == null) return null;
      if (result.status == PaymentPageResultStatus.success ||
          result.status == PaymentPageResultStatus.cancelled ||
          result.status == PaymentPageResultStatus.failed) {
        return result;
      }
    } catch (_) {}
    return null;
  }

  void _clearTransientErrorState() {
    lastHttpCode = null;
    _lastMainFrameError = null;
    _cancelPendingRecovery();
  }

  void _cancelPendingRecovery() {
    _pendingRecoveryTimer?.cancel();
    _pendingRecoveryTimer = null;
  }

  void _complete(PaymentPageResult result, {String? finalUrl}) {
    if (_completed || !mounted) return;

    _completed = true;
    _bootMaskTimer?.cancel();
    _hardTimeoutTimer?.cancel();
    _pendingRecoveryTimer?.cancel();
    _statusPollTimer?.cancel();

    Navigator.of(context).pop(
      PaymentPageResult(
        status: result.status,
        message: result.message,
        finalUrl: finalUrl ?? result.finalUrl,
      ),
    );
  }

  @override
  void dispose() {
    _bootMaskTimer?.cancel();
    _hardTimeoutTimer?.cancel();
    _pendingRecoveryTimer?.cancel();
    _statusPollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.allowManualClose,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Payment Processing'.tr),
          actions: [
            if (widget.allowManualClose)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  if (_completed) return;
                  _complete(
                    const PaymentPageResult(
                      status: PaymentPageResultStatus.cancelled,
                      message: 'Payment closed by user.',
                    ),
                    finalUrl: _currentUrl,
                  );
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
            if (!_completed && (_loading || _bootMaskVisible))
              const Positioned.fill(child: ColoredBox(color: Colors.white)),
            if (!_completed && (_loading || _bootMaskVisible))
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
