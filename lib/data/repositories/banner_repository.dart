import '../../../core/config/app_config.dart';
import '../../../core/services/api_service.dart';
import '../../modules/home/model/app_banner_model.dart';

class BannerRepository {
  final ApiService api;
  BannerRepository(this.api);

  Future<List<AppBanner>> fetchActiveBanners() async {
    final url = AppConfig.activeAppBannerUrl();
    final res = await api.getJson(url);

    final list = (res['data'] as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((e) => AppBanner.fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}
