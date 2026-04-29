class LeafModel {
  final int id;
  final String name;
  final String slug;

  const LeafModel({required this.id, required this.name, required this.slug});

  static int _i(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
  static String _s(dynamic v) => v?.toString() ?? '';

  factory LeafModel.fromJson(Map<String, dynamic> json) {
    return LeafModel(
      id: _i(json['id']),
      name: _s(json['name']),
      slug: _s(json['slug']),
    );
  }
}

class SubcategoryModel {
  final int id;
  final String name;
  final String slug;

  final List<LeafModel> children;

  const SubcategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.children = const [],
  });

  bool get isAll {
    final t = name.trim().toLowerCase();
    final s = slug.trim().toLowerCase();
    return s == 'all-products' ||
        s == 'all' ||
        t == 'all products' ||
        t == 'all' ||
        t == 'সব পণ্য' ||
        t == 'كل المنتجات';
  }

  bool get hasDropdown => children.isNotEmpty;

  static int _i(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
  static String _s(dynamic v) => v?.toString() ?? '';

  static List<dynamic> _childList(Map<String, dynamic> json) {
    final childs = json['childs'];
    if (childs is Map && childs['data'] is List) return childs['data'] as List;
    return const [];
  }

  factory SubcategoryModel.fromJson(Map<String, dynamic> json) {
    final rawLeaves = _childList(json);
    final leaves = rawLeaves
        .whereType<Map>()
        .map((e) => LeafModel.fromJson(e.cast<String, dynamic>()))
        .toList();

    return SubcategoryModel(
      id: _i(json['id']),
      name: _s(json['name']),
      slug: _s(json['slug']),
      children: leaves,
    );
  }
}
