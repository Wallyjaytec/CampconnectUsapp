import 'dart:convert';

import '../../core/config/app_config.dart';
import '../../core/services/api_service.dart';
import '../../modules/compare/model/compare_model.dart';

class CompareRepository {
  final ApiService api;

  CompareRepository(this.api);

  Future<List<CompareItemModel>> fetchCompareItems(List<int> ids) async {
    if (ids.isEmpty) return <CompareItemModel>[];

    final payload = jsonEncode(ids);
    final body = 'items=${Uri.encodeQueryComponent(payload)}';

    final res = await api.postFormUrlEncodedRaw(
      AppConfig.compareItemsDetailsUrl(),
      body: body,
    );

    final data = res['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((j) => CompareItemModel.fromJson(j))
          .toList();
    }
    return <CompareItemModel>[];
  }
}
