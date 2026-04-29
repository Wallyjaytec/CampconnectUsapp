import '../../../core/config/app_config.dart';

class Brand {
  final int id;
  final String name;
  final String slug;
  final String logo;

  Brand({
    required this.id,
    required this.name,
    required this.slug,
    required this.logo,
  });

  String get logoUrl => AppConfig.assetUrl(logo);

  factory Brand.fromJson(Map<String, dynamic> j) {
    return Brand(
      id: (j['id'] as num).toInt(),
      name: (j['name'] ?? '').toString(),
      slug: (j['slug'] ?? '').toString(),
      logo: (j['logo'] ?? '').toString(),
    );
  }
}
