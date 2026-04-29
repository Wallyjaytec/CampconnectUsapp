import '../../core/config/app_config.dart';
import '../../core/services/api_service.dart';
import '../../modules/product/model/flash_deal_models.dart';

class FlashDealRepository {
  final ApiService api;
  FlashDealRepository(this.api);

  Future<List<FlashDealSummary>> fetchActiveDeals() async {
    final url = AppConfig.flashDealsActiveUrl();
    final res = await api.postJson(url, body: {});
    final list = (res['data'] as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((e) => FlashDealSummary.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<FlashDealDetails> fetchDealDetails(int id) async {
    final url = AppConfig.flashDealDetailsUrl();
    final res = await api.postJson(url, body: {'id': id});
    final data = (res['data'] as Map? ?? const {}).cast<String, dynamic>();
    return FlashDealDetails.fromJson(data);
  }

  Future<FDPaginated> fetchDealProducts({
    required int id,
    required int page,
    required int perPage,
  }) async {
    final url = AppConfig.flashDealProductsUrl();
    final res = await api.postJson(
      url,
      body: {'id': id, 'page': page, 'perPage': perPage},
    );
    return FDPaginated.fromJson(res.cast<String, dynamic>());
  }
}
