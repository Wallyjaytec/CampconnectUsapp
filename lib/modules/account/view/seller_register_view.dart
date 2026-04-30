import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SellerRegisterView extends StatelessWidget {
  const SellerRegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Become a Seller'),
      ),
      body: const WebView(
        initialUrl: 'https://campconnectus.store/seller/register',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}
