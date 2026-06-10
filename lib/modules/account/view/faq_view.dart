import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/widgets/back_icon_widget.dart';

class FaqView extends StatefulWidget {
  const FaqView({super.key});

  @override
  State<FaqView> createState() => _FaqViewState();
}

class _FaqViewState extends State<FaqView> {
  String _title = '';
  String _content = '';
  String? _featuredImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPage();
  }

  Future<void> _fetchPage() async {
    try {
      final lang = Get.locale?.languageCode ?? 'en';
      final uri = Uri.parse(AppConfig.pageBySlugUrl());
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'slug': 'f-a-q', 'lang': lang}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _title = data['data']['title'] ?? 'FAQ';
            _content = data['data']['content'] ?? '';
            _featuredImage = data['data']['featured_image'];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    setState(() {
      _title = 'FAQ';
      _content = '<p>Content not available.</p>';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        leading: const BackIconWidget(),
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          _title.isNotEmpty ? _title : 'FAQ'.tr,
          style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_featuredImage != null && _featuredImage!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: _featuredImage!,
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    HtmlWidget(
                      _content,
                      baseUrl: Uri.parse(AppConfig.baseUrl),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
