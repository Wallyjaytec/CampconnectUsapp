import '../../core/config/app_config.dart';
import '../../core/services/api_service.dart';
import '../../modules/category/model/category_model.dart';

class CategoryRepository {
  final ApiService api;
  CategoryRepository(this.api);

  Future<Map<int, String>> _fetchParentIcons() async {
    final json = await api.getJson(AppConfig.parentCategoriesUrl());
    final list = (json['data'] as List?) ?? const [];
    final map = <int, String>{};
    for (final item in list) {
      if (item is Map) {
        final m = item.cast<String, dynamic>();
        final id = _asInt(m['id']);
        final icon = (m['icon'] ?? '').toString();
        if (id != 0 && icon.isNotEmpty) {
          map[id] = icon;
        }
      }
    }
    return map;
  }

  Future<List<CategoryModel>> fetchMegaCategories() async {
    final iconMap = await _fetchParentIcons();

    final json = await api.getJson(AppConfig.megaCategoriesUrl());
    final list = (json['data'] as List?) ?? const [];

    final out = <CategoryModel>[];
    for (final item in list) {
      if (item is Map) {
        final m = item.cast<String, dynamic>();
        final id = _asInt(m['id']);
        final overrideIcon = iconMap[id];
        out.add(CategoryModel.fromMegaJson(m, iconOverride: overrideIcon));
      }
    }
    return out;
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
