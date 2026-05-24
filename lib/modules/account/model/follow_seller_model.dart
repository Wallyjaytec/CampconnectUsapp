class FollowSellerModel {
  final int id;
  final String name;
  final String slug;
  final String logo;
  final String? shopBanner;
  final int totalFollowers;
  final int positiveRating;
  final bool isVerified;
  final bool isFollowing;

  FollowSellerModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.logo,
    this.shopBanner,
    required this.totalFollowers,
    required this.positiveRating,
    required this.isVerified,
    required this.isFollowing,
  });

  factory FollowSellerModel.fromJson(Map<String, dynamic> json) {
    return FollowSellerModel(
      id: json['id'] is String
          ? int.tryParse(json['id']) ?? 0
          : (json['id'] ?? 0),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      logo: json['logo']?.toString() ?? '',
      shopBanner: json['shop_banner']?.toString(),
      totalFollowers: json['total_followers'] is String
          ? int.tryParse(json['total_followers']) ?? 0
          : (json['total_followers'] ?? 0),
      positiveRating: json['positive_rating'] is String
          ? int.tryParse(json['positive_rating']) ?? 0
          : (json['positive_rating'] ?? 0),
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      isFollowing: json['is_following'] == true || json['is_following'] == 1,
    );
  }

  String get followersText {
    if (totalFollowers >= 1000000) {
      final v = totalFollowers / 1000000;
      return '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1)}M Followers';
    } else if (totalFollowers >= 1000) {
      final v = totalFollowers / 1000;
      return '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1)}k Followers';
    }
    return '$totalFollowers Followers';
  }
}
