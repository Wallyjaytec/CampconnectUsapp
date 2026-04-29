import '../../../core/config/app_config.dart';
import '../../../core/services/api_service.dart';
import '../../modules/product/model/product_details_model.dart';

class ProductDetailsRepository {
  final ApiService api;
  ProductDetailsRepository(this.api);

  Future<ProductDetailsModel> fetchByPermalink(String permalink) async {
    final url = AppConfig.productDetailsUrl();

    final res = await api.postJson(url, body: {'permalink': permalink});

    return ProductDetailsModel.fromJson(res);
  }
}
