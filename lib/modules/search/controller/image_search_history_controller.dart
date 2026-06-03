import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ImageSearchHistoryItem {
  final String imagePath;
  final DateTime timestamp;
  
  ImageSearchHistoryItem({required this.imagePath, required this.timestamp});
  
  Map<String, dynamic> toJson() => {
    'imagePath': imagePath,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };
  
  factory ImageSearchHistoryItem.fromJson(Map<String, dynamic> json) => ImageSearchHistoryItem(
    imagePath: json['imagePath'] ?? '',
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
  );
}

class ImageSearchHistoryController extends GetxController {
  final _box = GetStorage();
  static const _key = 'image_search_history';
  
  final RxList<ImageSearchHistoryItem> history = <ImageSearchHistoryItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadHistory();
  }

  void _loadHistory() {
    final raw = _box.read<String>(_key);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        history.assignAll(list.map((e) => ImageSearchHistoryItem.fromJson(e)));
        // Remove items older than 30 days
        final cutoff = DateTime.now().subtract(const Duration(days: 30));
        history.removeWhere((item) => item.timestamp.isBefore(cutoff));
        _saveHistory();
      } catch (_) {}
    }
  }

  void _saveHistory() {
    final json = jsonEncode(history.map((e) => e.toJson()).toList());
    _box.write(_key, json);
  }

  void addToHistory(String imagePath) {
    history.insert(0, ImageSearchHistoryItem(imagePath: imagePath, timestamp: DateTime.now()));
    _saveHistory();
  }

  void deleteItem(int index) {
    if (index >= 0 && index < history.length) {
      history.removeAt(index);
      _saveHistory();
    }
  }

  void deleteSelected(Set<int> indices) {
    final sortedIndices = indices.toList()..sort((a, b) => b.compareTo(a));
    for (final index in sortedIndices) {
      if (index < history.length) {
        history.removeAt(index);
      }
    }
    _saveHistory();
  }

  void clearAll() {
    history.clear();
    _saveHistory();
  }
}
