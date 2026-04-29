import '../../core/config/app_config.dart';
import '../../core/services/api_service.dart';
import '../../modules/product/model/review_model.dart';

class ProductReviewsRepository {
  final ApiService api;
  ProductReviewsRepository(this.api);

  Future<ProductReviewsPage> fetch({
    required int productId,
    int page = 1,
    int perPage = 10,
    String sorting = 'DESC',
  }) async {
    final url = AppConfig.productReviewsUrl();
    final body = {
      'page': page,
      'perPage': perPage,
      'product_id': productId,
      'sorting': sorting,
    };

    final res = await api.postJson(url, body: body);
    return ProductReviewsPage.fromJson(res);
  }
}
