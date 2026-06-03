import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class VisualSearchService {
  Future<List<Map<String, dynamic>>> searchByImage(File imageFile) async {
    final uri = Uri.parse(AppConfig.visualSearchUrl());
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    request.fields['limit'] = '10';
    
    final response = await request.send();
    final body = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      // Parse response
      return [];
    }
    return [];
  }
}
