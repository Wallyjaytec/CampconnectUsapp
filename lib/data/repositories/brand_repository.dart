import '../../core/config/app_config.dart';
import '../../core/services/api_service.dart';
import '../../modules/product/model/brand_model.dart';

class BrandRepository {
  final ApiService _api;
  BrandRepository({ApiService? api}) : _api = api ?? ApiService();

  Future<List<Brand>> fetchAll() async {
    final res = await _api.getJson(AppConfig.brandsUrl());
    final list = (res['data'] as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((e) => Brand.fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}
