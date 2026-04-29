class AppBanner {
  final int id;
  final String title;
  final String image;
  final String type;
  final String? value;

  const AppBanner({
    required this.id,
    required this.title,
    required this.image,
    required this.type,
    required this.value,
  });

  factory AppBanner.fromJson(Map<String, dynamic> json) {
    return AppBanner(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      title: json['title']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      value: json['value']?.toString(),
    );
  }

  String get normalizedType => type.toLowerCase().trim();

  int? get valueAsInt {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    return int.tryParse(v);
  }

  bool get valueLooksLikeUrl {
    final v = (value ?? '').trim();
    if (v.isEmpty) return false;
    return v.startsWith('http://') ||
        v.startsWith('https://') ||
        v.startsWith('www.') ||
        v.startsWith('//');
  }
}
