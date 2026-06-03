import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class VisualSearchResult {
  final String productId;
  final String title;
  final String imageUrl;
  final String price;
  final double score;

  VisualSearchResult({
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.score,
  });

  factory VisualSearchResult.fromJson(Map<String, dynamic> json) {
    return VisualSearchResult(
      productId: json['product_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      score: (json['score'] is num) ? (json['score'] as num).toDouble() : 0.0,
    );
  }
}

class VisualSearchService {
  Future<List<VisualSearchResult>> searchByImage(File imageFile) async {
    try {
      final uri = Uri.parse(AppConfig.visualSearchUrl());
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      request.fields['limit'] = '10';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['products'] != null) {
          final list = data['products'] as List;
          return list.map((e) => VisualSearchResult.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
