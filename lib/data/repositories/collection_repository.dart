import 'package:campconnectus_marketplace/core/config/app_config.dart';
import 'package:campconnectus_marketplace/core/services/api_service.dart';

import '../../modules/collection/model/collection_model.dart';

class CollectionRepository {
  final ApiService _api;

  CollectionRepository({ApiService? api}) : _api = api ?? ApiService();

  Future<CollectionDetails> fetchDetails({required int id}) async {
    final res = await _api.postMultipart(
      AppConfig.collectionDetailsUrl(),
      fields: {'id': '$id'},
    );
    return CollectionDetails.fromJson(res);
  }

  Future<CollectionProductsResponse> fetchProducts({
    required int id,
    int page = 1,
    int perPage = 10,
  }) async {
    final res = await _api.postMultipart(
      AppConfig.collectionAllProductsUrl(),
      fields: {'id': '$id', 'page': '$page', 'perPage': '$perPage'},
    );
    return CollectionProductsResponse.fromJson(res);
  }
}
