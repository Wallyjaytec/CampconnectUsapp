import '../../../core/config/app_config.dart';

class ProductDetailsModel {
  final int id;
  final String name;
  final String permalink;
  final double price;
  final double? oldPrice;

  final double? priceRangeMin;
  final double? priceRangeMax;

  final double? priceRangeMinOld;
  final double? priceRangeMaxOld;

  final int quantity;
  final int totalReviews;
  final double rating;
  final bool hasVariant;

  final List<GalleryItem> galleryImages;
  final String? pdfSpec;
  final int maxItemOnPurchase;
  final int minItemOnPurchase;
  final bool hasWarranty;
  final bool hasReplacementWarranty;
  final int warrantyDays;
  final String isAuthentic;
  final String isActiveCod;
  final String descriptionHtml;
  final String summaryHtml;
  final String condition;
  final bool isRefundable;
  final String returnOption;
  final String url;
  final Discount? applicableDiscount;
  final List<ShareOption> shareOptions;
  final ShopInfo shopInfo;
  final String seller;

  final List<AttributeGroup> attributes;
  final VariantPrice? selectedVariant;

  final String? attachmentTitle;

  const ProductDetailsModel({
    required this.id,
    required this.name,
    required this.permalink,
    required this.price,
    required this.oldPrice,
    required this.priceRangeMin,
    required this.priceRangeMax,
    this.priceRangeMinOld,
    this.priceRangeMaxOld,
    required this.quantity,
    required this.totalReviews,
    required this.rating,
    required this.hasVariant,
    required this.galleryImages,
    required this.pdfSpec,
    required this.maxItemOnPurchase,
    required this.minItemOnPurchase,
    required this.hasWarranty,
    required this.hasReplacementWarranty,
    required this.warrantyDays,
    required this.isAuthentic,
    required this.isActiveCod,
    required this.descriptionHtml,
    required this.summaryHtml,
    required this.condition,
    required this.isRefundable,
    required this.returnOption,
    required this.url,
    required this.applicableDiscount,
    required this.shareOptions,
    required this.shopInfo,
    required this.seller,
    required this.attributes,
    required this.selectedVariant,
    this.attachmentTitle,
  });

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map) return v.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  static List _asList(dynamic v) {
    if (v is List) return v;
    return const [];
  }

  static String _s(dynamic v) => v?.toString() ?? '';

  static int _i(dynamic v) {
    if (v is int) return v;
    return int.tryParse(_s(v)) ?? 0;
  }

  static double _d(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(_s(v)) ?? 0.0;
  }

  static double? _dn(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = _s(v).trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    return double.tryParse(s);
  }

  static bool _bFlexible(dynamic v) {
    final s = _s(v).trim().toLowerCase();
    if (s.isEmpty) return false;
    return s == '1' || s == 'true' || s == 'yes';
  }

  factory ProductDetailsModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = json.containsKey('data')
        ? _asMap(json['data'])
        : json;

    final galleryList = _asList(
      data['galleryImages'],
    ).whereType<Map>().map((e) => GalleryItem.fromJson(_asMap(e))).toList();

    final shareList = _asList(
      data['shareOptions'],
    ).whereType<Map>().map((e) => ShareOption.fromJson(_asMap(e))).toList();

    final shop = ShopInfo.fromJson(_asMap(data['shopInfo']));

    final price = _d(data['price']);
    final old = _d(data['oldPrice']);
    final oldPrice = (old > price) ? old : null;

    Discount? discount;
    final discMap = _asMap(data['applicable_discount']);
    if (discMap.isNotEmpty) discount = Discount.fromJson(discMap);

    final attrs = _asList(
      data['attribute'],
    ).whereType<Map>().map((e) => AttributeGroup.fromJson(_asMap(e))).toList();

    VariantPrice? selVar;
    final selMap = _asMap(data['selectedVariant']);
    if (selMap.isNotEmpty) selVar = VariantPrice.fromJson(selMap);

    final attachmentTitleRaw = _s(data['attatchment_title']).trim();
    final String? attachmentTitle = attachmentTitleRaw.isEmpty
        ? null
        : attachmentTitleRaw;

    return ProductDetailsModel(
      id: _i(data['id']),
      name: _s(data['name']),
      permalink: _s(data['permalink']),
      price: price,
      oldPrice: oldPrice,
      priceRangeMin: _dn(data['price_range_min']),
      priceRangeMax: _dn(data['price_range_max']),
      priceRangeMinOld: _dn(data['price_range_min_old']),
      priceRangeMaxOld: _dn(data['price_range_max_old']),
      quantity: _i(data['quantity']),
      totalReviews: _i(data['total_reviews']),
      rating: _d(data['rating']),
      hasVariant: (() {
        final hv = _i(data['has_variant']);
        return hv == 1 || hv == 2;
      })(),
      galleryImages: galleryList,
      pdfSpec: _s(data['pdf_specifications']).trim().isEmpty
          ? null
          : _s(data['pdf_specifications']),
      maxItemOnPurchase: _i(data['max_item_on_purchase']),
      minItemOnPurchase: _i(data['min_item_on_purchase']),
      hasWarranty: _bFlexible(data['has_warranty']),
      hasReplacementWarranty: _bFlexible(data['has_replacement_warranty']),
      warrantyDays: _i(data['warrenty_days']),
      isAuthentic: _s(data['is_authentic']),
      isActiveCod: _s(data['is_active_cod']),
      descriptionHtml: _s(data['description']),
      summaryHtml: _s(data['summary']),
      condition: _s(data['condition']),
      isRefundable: _bFlexible(data['is_refundable']),
      returnOption: _s(data['return_option']),
      url: _s(data['url']),
      applicableDiscount: discount,
      shareOptions: shareList,
      shopInfo: shop,
      seller: _s(data['seller']),
      attributes: attrs,
      selectedVariant: selVar,
      attachmentTitle: attachmentTitle,
    );
  }
}

class GalleryItem {
  final String? regular;
  final String? zoom;
  final String type;
  final String? videoLink;
  final String? thumbnail;

  GalleryItem({
    required this.regular,
    required this.zoom,
    required this.type,
    this.videoLink,
    this.thumbnail,
  });

  String get imageUrl => _normalize(regular ?? zoom ?? '');

  bool get isVideo => type.toLowerCase() == 'video';

  String get videoThumb {
    if ((thumbnail ?? '').trim().isNotEmpty) return _normalize(thumbnail!);
    final id = _extractYouTubeId(videoLink ?? '');
    if (id != null) return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
    return '';
  }

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v?.toString() ?? '';
    String? n(String v) => v.trim().isEmpty ? null : v.trim();

    final type = s(json['type']).trim();

    return GalleryItem(
      regular: n(s(json['regular'])),
      zoom: n(s(json['zoom'])),
      type: type.isEmpty ? 'image' : type,
      videoLink: n(s(json['video_link'])),
      thumbnail: n(s(json['thumbnail'])),
    );
  }

  Map<String, dynamic> toJson() => {
    'regular': regular,
    'zoom': zoom,
    'type': type,
    'video_link': videoLink,
    'thumbnail': thumbnail,
  };

  static String _normalize(String raw) {
    final u = raw.trim();
    if (u.isEmpty) return '';
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    if (u.startsWith('/')) return AppConfig.assetUrl(u);
    return u;
  }

  static String? _extractYouTubeId(String url) {
    final u = url.toLowerCase();
    if (!(u.contains('youtube.com/') || u.contains('youtu.be/'))) return null;
    final patterns = <RegExp>[
      RegExp(r'[?&]v=([0-9A-Za-z_-]{11})'),
      RegExp(r'youtu\.be/([0-9A-Za-z_-]{11})'),
      RegExp(r'embed/([0-9A-Za-z_-]{11})'),
      RegExp(r'shorts/([0-9A-Za-z_-]{11})'),
    ];
    for (final re in patterns) {
      final m = re.firstMatch(url);
      if (m != null && m.groupCount >= 1) return m.group(1);
    }
    return null;
  }
}

class Discount {
  final String discountAmount;
  final String discountType;
  Discount({required this.discountAmount, required this.discountType});

  factory Discount.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v?.toString() ?? '';
    return Discount(
      discountAmount: s(json['discount_amount']),
      discountType: s(json['discountType']),
    );
  }
}

class ShareOption {
  final String network;
  final String name;
  final String icon;
  ShareOption({required this.network, required this.name, required this.icon});

  factory ShareOption.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v?.toString() ?? '';
    return ShareOption(
      network: s(json['network']),
      name: s(json['name']),
      icon: s(json['icon']),
    );
  }
}

class ShopInfo {
  final int id;
  final String name;
  final String slug;
  final String logo;
  final String shopBanner;
  final String? address;
  final String? phone;
  final int totalFollowers;
  final int totalProduct;
  final String positiveRating;
  final double avgRating;
  final bool isFollowing;

  ShopInfo({
    required this.id,
    required this.name,
    required this.slug,
    required this.logo,
    required this.shopBanner,
    required this.address,
    required this.phone,
    required this.totalFollowers,
    required this.totalProduct,
    required this.positiveRating,
    required this.avgRating,
    required this.isFollowing,
  });

  factory ShopInfo.fromJson(Map<String, dynamic> json) {
    int i(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    double d(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    String s(dynamic v) => v?.toString() ?? '';

    return ShopInfo(
      id: i(json['id']),
      name: s(json['name']),
      slug: s(json['slug']),
      logo: AppConfig.assetUrl(s(json['logo'])),
      shopBanner: AppConfig.assetUrl(s(json['shop_banner'])),
      address: s(json['shop_address']).trim().isEmpty
          ? null
          : s(json['shop_address']),
      phone: s(json['shop_phone']).trim().isEmpty
          ? null
          : s(json['shop_phone']),
      totalFollowers: i(json['total_followers']),
      totalProduct: i(json['total_product']),
      positiveRating: s(json['positive_rating']),
      avgRating: d(json['avg_rating']),
      isFollowing: json['is_following'] == true || json['is_following'] == 1,
    );
  }
}

class AttributeGroup {
  final String id;
  final String name;
  final bool required;
  final List<AttributeOption> options;

  AttributeGroup({
    required this.id,
    required this.name,
    required this.required,
    required this.options,
  });

  String get title => name;

  factory AttributeGroup.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v?.toString() ?? '';
    bool b(dynamic v) {
      final s1 = s(v).trim().toLowerCase();
      return s1 == '1' || s1 == 'true' || s1 == 'yes';
    }

    final rawOptions = ProductDetailsModel._asList(json['options'])
        .whereType<Map>()
        .map((e) => AttributeOption.fromJson(ProductDetailsModel._asMap(e)))
        .toList();

    final resolvedName = (() {
      final t = s(json['title']).trim();
      if (t.isNotEmpty) return t;
      final n = s(json['name']).trim();
      if (n.isNotEmpty) return n;
      return s(json['id']);
    })();

    return AttributeGroup(
      id: s(json['id']),
      name: resolvedName,
      required: b(json['required']),
      options: rawOptions,
    );
  }
}

class AttributeOption {
  final String id;
  final String parent;
  final String label;

  final double? price;
  final double? oldPrice;
  final int? stock;

  final String? valueHex;
  final String? imageUrl;
  final String? rawName;

  AttributeOption({
    required this.id,
    required this.parent,
    required this.label,
    this.price,
    this.oldPrice,
    this.stock,
    this.valueHex,
    this.imageUrl,
    this.rawName,
  });

  String get name => rawName ?? label;
  String? get value => valueHex;
  String get title => label;
  String? get image => imageUrl;
  String? get hex => valueHex;

  factory AttributeOption.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => v?.toString() ?? '';

    double? dn(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      final s = v.toString().trim();
      if (s.isEmpty || s.toLowerCase() == 'null') return null;
      return double.tryParse(s);
    }

    int? in1(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    final resolvedLabel = (() {
      final t = json['title']?.toString().trim();
      if (t != null && t.isNotEmpty) return t;
      final l = json['label']?.toString().trim();
      if (l != null && l.isNotEmpty) return l;
      final n = json['name']?.toString().trim();
      if (n != null && n.isNotEmpty) return n;
      return '';
    })();

    final valueHex = s(json['value']).trim();
    final image = s(json['image']).trim();
    final rawName = s(json['name']).trim();

    return AttributeOption(
      id: s(json['id']),
      parent: s(json['parent']),
      label: resolvedLabel,
      price: dn(json['price']),
      oldPrice: dn(json['oldPrice'] ?? json['base_price']),
      stock: in1(json['stock']),
      valueHex: valueHex.isNotEmpty ? valueHex : null,
      imageUrl: image.isNotEmpty ? image : null,
      rawName: rawName.isNotEmpty ? rawName : null,
    );
  }
}

class VariantPrice {
  final double? price;
  final double? oldPrice;
  VariantPrice({this.price, this.oldPrice});

  factory VariantPrice.fromJson(Map<String, dynamic> json) {
    double? dn(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      final s = v.toString().trim();
      if (s.isEmpty || s.toLowerCase() == 'null') return null;
      return double.tryParse(s);
    }

    return VariantPrice(
      price: dn(json['price']),
      oldPrice: dn(json['oldPrice'] ?? json['base_price']),
    );
  }
}
