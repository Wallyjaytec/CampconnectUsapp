import '../../../core/config/app_config.dart';
import 'subcategory_model.dart';

class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String icon;
  final List<SubcategoryModel> subcategories;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
    this.subcategories = const [],
  });

  String get imageUrl => AppConfig.assetUrl(icon);

  static int _i(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
  static String _s(dynamic v) => v?.toString() ?? '';

  static List<dynamic> _childList(Map<String, dynamic> json) {
    final childs = json['childs'];
    if (childs is Map && childs['data'] is List) return childs['data'] as List;
    return const [];
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final subsRaw = _childList(json);
    return CategoryModel(
      id: _i(json['id']),
      name: _s(json['name']),
      slug: _s(json['slug']),
      icon: _s(json['icon']),
      subcategories: subsRaw
          .whereType<Map>()
          .map((e) => SubcategoryModel.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  factory CategoryModel.fromMegaJson(
    Map<String, dynamic> json, {
    String? iconOverride,
  }) {
    final subsRaw = _childList(json);
    final rawIcon = iconOverride ?? _s(json['icon']);
    return CategoryModel(
      id: _i(json['id']),
      name: _s(json['name']),
      slug: _s(json['slug']),
      icon: rawIcon,
      subcategories: subsRaw
          .whereType<Map>()
          .map((e) => SubcategoryModel.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}
