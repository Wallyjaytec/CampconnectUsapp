import '../../core/config/app_config.dart';
import '../../core/services/api_service.dart';
import '../../modules/product/model/related_product_model.dart';

class RelatedProductsRepository {
  final ApiService _api;
  RelatedProductsRepository(this._api);

  Future<List<RelatedProduct>> fetchRelated({required int productId}) async {
    const url = AppConfig.baseUrl + AppConfig.relatedProductsPath;

    final resp = await _api.postJson(url, body: {"id": productId});

    final Map<String, dynamic> map = (resp as Map).cast<String, dynamic>();

    final data = map['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => RelatedProduct.fromJson(e.cast<String, dynamic>()))
          .toList();
    }

    return <RelatedProduct>[];
  }
}
