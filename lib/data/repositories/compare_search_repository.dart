import '../../../core/config/app_config.dart';
import '../../../core/services/api_service.dart';
import '../../modules/compare/model/compare_model.dart';

class CompareSearchRepository {
  final ApiService api;
  CompareSearchRepository(this.api);

  Future<List<CompareSuggestionItem>> fetchSuggestions(String query) async {
    if (query.trim().isEmpty) return const [];

    final url = AppConfig.searchSuggestionsUrl();
    final res = await api.postMultipart(url, fields: {'search_key': query});

    final dynamic root =
        res['data'] ?? res['results'] ?? res['products'] ?? res['items'];

    if (root is! List) return const [];

    int parseId(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    int extractId(Map<String, dynamic> m) {
      final keys = ['id', 'product_id', 'productId', 'item_id', 'itemId'];
      for (final k in keys) {
        if (m.containsKey(k)) {
          final id = parseId(m[k]);
          if (id > 0) return id;
        }
      }
      if (m['product'] is Map<String, dynamic>) {
        final id = parseId((m['product'] as Map<String, dynamic>)['id']);
        if (id > 0) return id;
      }
      return 0;
    }

    return root.map<CompareSuggestionItem>((e) {
      final m = (e as Map<String, dynamic>);
      final id = extractId(m);
      final name =
          m['name']?.toString() ??
          m['title']?.toString() ??
          m['slug']?.toString() ??
          'Unknown';
      final thumb = m['thumbnail_image']?.toString() ?? m['image']?.toString();

      return CompareSuggestionItem(id: id, name: name, thumbnail: thumb);
    }).toList();
  }
}
