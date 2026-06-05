import 'package:campconnectus_marketplace/core/config/app_config.dart';
import 'package:campconnectus_marketplace/core/services/api_service.dart';
import 'package:campconnectus_marketplace/modules/search/model/search_model.dart';

class SearchRepository {
  final ApiService api;
  SearchRepository({required this.api});

  Future<SearchProductsResponse> searchProducts({
    String brandId = '',
    String categoryId = '',
    int page = 1,
    int perPage = 20,
    String priceRange = '',
    String rating = '',
    String sorting = 'newest',
    required String searchKey,
    String tag = '',
  }) async {
    final url = AppConfig.searchProductsUrl();
    final body = {
      'brand_id': brandId,
      'category_id': categoryId,
      'page': page,
      'perPage': perPage,
      'price_range': priceRange,
      'rating': rating,
      'sorting': sorting,
      'search_key': searchKey,
      'tag': tag,
    };
    final json = await api.postJson(url, body: body);
    return SearchProductsResponse.fromJson(json);
  }

  Future<SearchSuggestionsResponse> getSuggestions(String searchKey) async {
    final url = AppConfig.searchSuggestionsUrl();
    final json = await api.postMultipart(
      url,
      fields: {'search_key': searchKey},
    );
    return SearchSuggestionsResponse.fromJson(json);
  }
}
