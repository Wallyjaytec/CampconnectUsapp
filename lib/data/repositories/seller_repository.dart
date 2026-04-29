import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/services/api_service.dart';
import '../../modules/seller/model/seller_all_products_model.dart';
import '../../modules/seller/model/seller_shop_model.dart';
import '../../modules/seller/model/shop_review_model.dart';

class SellerRepository {
  final ApiService api;
  SellerRepository({ApiService? apiService}) : api = apiService ?? ApiService();

  Future<ShopProductSummaryResponse> fetchShopProductSummary({
    required String slug,
  }) async {
    final url = AppConfig.shopProductsSummaryUrl();
    final res = await api.postMultipart(
      url,
      fields: {'slug': slug},
      headers: {},
      files: const <http.MultipartFile>[],
    );
    return ShopProductSummaryResponse.fromMap(res);
  }

  Future<FollowShopResponse> followShop({required String slug}) async {
    final url = AppConfig.followShopUrl();
    final res = await api.postMultipart(url, fields: {'slug': slug});
    return FollowShopResponse.fromJson(res);
  }

  Future<SellerAllProductsResponse> fetchShopAllProducts({
    required String slug,
    required int page,
    required int perPage,
    String sorting = 'newest',
    int? categoryId,
    int? brandId,
    double? minPrice,
    double? maxPrice,
    int? rating,
  }) async {
    final url = AppConfig.shopAllProductsUrl();

    final fields = <String, String>{
      'slug': slug,
      'page': '$page',
      'perPage': '$perPage',
      'shorting': sorting,
    };

    if (categoryId != null && categoryId > 0) {
      fields['category_id'] = '$categoryId';
    }
    if (brandId != null && brandId > 0) {
      fields['brand_id'] = '$brandId';
    }
    if (minPrice != null && minPrice > 0) {
      fields['min_price'] = minPrice.toString();
    }
    if (maxPrice != null && maxPrice > 0) {
      fields['max_price'] = maxPrice.toString();
    }
    if (rating != null && rating > 0) {
      fields['rating'] = '$rating';
    }

    final res = await api.postMultipart(url, fields: fields);
    return SellerAllProductsResponse.fromJson(res);
  }

  Future<ShopReviewsResponse> fetchShopReviews({
    required String slug,
    required int page,
    required int perPage,
    required String sorting,
  }) async {
    final url = AppConfig.shopAllReviewsUrl();

    final fields = <String, String>{
      'slug': slug,
      'page': '$page',
      'perPage': '$perPage',
      'sorting': sorting,
    };

    final res = await api.postMultipart(
      url,
      fields: fields,
      headers: {},
      files: const <http.MultipartFile>[],
    );

    return ShopReviewsResponse.fromJson(res);
  }
}
