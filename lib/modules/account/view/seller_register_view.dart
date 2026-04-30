import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SellerRegisterView extends StatefulWidget {
  const SellerRegisterView({super.key});

  @override
  State<SellerRegisterView> createState() => _SellerRegisterViewState();
}

class _SellerRegisterViewState extends State<SellerRegisterView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://campconnectus.store/seller/register'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Seller'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
