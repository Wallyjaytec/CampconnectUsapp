import '../../core/config/app_config.dart';
import '../../core/services/api_service.dart';

class VariantInfoResponse {
  final bool success;
  final String? newVariant;
  final double? basePrice;
  final double? oldPrice;
  final int quantity;

  VariantInfoResponse({
    required this.success,
    this.newVariant,
    this.basePrice,
    this.oldPrice,
    required this.quantity,
  });

  factory VariantInfoResponse.fromMap(Map<String, dynamic> m) {
    double? toD(v) => (v is num) ? v.toDouble() : double.tryParse('$v');
    int toI(v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;

    return VariantInfoResponse(
      success: (m['success'] == true) || (m['success']?.toString() == 'true'),
      newVariant: m['new_variant']?.toString(),
      basePrice: toD(m['base_price']),
      oldPrice: toD(m['oldPrice'] ?? m['old_price']),
      quantity: toI(m['quantity']),
    );
  }
}

class VariantImageItem {
  final String regular;
  final String? zoom;
  final String? type;
  VariantImageItem({required this.regular, this.zoom, this.type});

  factory VariantImageItem.fromMap(Map<String, dynamic> m) {
    return VariantImageItem(
      regular: AppConfig.assetUrl(m['regular']?.toString()),
      zoom: AppConfig.assetUrl(m['zoom']?.toString()),
      type: m['type']?.toString(),
    );
  }
}

class VariantImagesResponse {
  final bool success;
  final List<VariantImageItem> images;
  VariantImagesResponse({required this.success, required this.images});

  factory VariantImagesResponse.fromMap(Map<String, dynamic> m) {
    final ok = (m['success'] == true) || (m['success']?.toString() == 'true');
    final list = <VariantImageItem>[];
    final raw = m['images'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) list.add(VariantImageItem.fromMap(e));
      }
    }
    return VariantImagesResponse(success: ok, images: list);
  }
}

String _buildSelectedVariantSlash(Map<String, String> byKey) {
  final map = Map<String, String>.from(byKey);
  map.remove('color');
  if (map.isEmpty) return '';
  final keys = map.keys.toList();
  return keys.map((k) => '$k:${map[k]}').join('/');
}

String _buildVariantExact(Map<String, String> byKey) {
  final map = Map<String, String>.from(byKey);
  final color = (map['color'] ?? '').trim();
  map.remove('color');

  final nonColor = _buildSelectedVariantSlash(byKey);
  if (nonColor.isEmpty && color.isEmpty) return '';

  if (nonColor.isNotEmpty && color.isNotEmpty) {
    return '$nonColor'
        'color:$color';
  } else if (nonColor.isNotEmpty) {
    return nonColor;
  } else {
    return 'color:$color';
  }
}

class ProductVariantRepository {
  ProductVariantRepository(this._api);
  final ApiService _api;

  Future<VariantInfoResponse> fetchVariantInfoByKey({
    required int productId,
    required Map<String, String> selectionsByKey,
    required String changedBackendKey,
  }) async {
    final map = <String, String>{};
    selectionsByKey.forEach((k, v) {
      final kk = k.trim();
      final vv = v.trim();
      if (kk.isNotEmpty && vv.isNotEmpty) map[kk] = vv;
    });

    final selectedVariantSlash = _buildSelectedVariantSlash(map);
    final variantExact = _buildVariantExact(map);

    final fields = <String, String>{
      'id': '$productId',
      'choice': changedBackendKey,
      'option': map[changedBackendKey] ?? '',
      if (selectedVariantSlash.isNotEmpty)
        'selectedVariant': selectedVariantSlash,
      if (variantExact.isNotEmpty) 'variant': variantExact,
    };

    try {
      final res = await _api.postMultipart(
        AppConfig.singleVariantInfoUrl(),
        fields: fields,
      );
      final parsed = VariantInfoResponse.fromMap(res);

      return parsed;
    } catch (e) {
      return VariantInfoResponse(success: false, quantity: 0);
    }
  }

  Future<VariantImagesResponse> fetchVariantImagesByKey({
    required int productId,
    required Map<String, String> selectionsByKey,
  }) async {
    final map = <String, String>{};
    selectionsByKey.forEach((k, v) {
      final kk = k.trim();
      final vv = v.trim();
      if (kk.isNotEmpty && vv.isNotEmpty) map[kk] = vv;
    });

    final variantExact = _buildVariantExact(map);

    final fields = <String, String>{
      'id': '$productId',
      if (variantExact.isNotEmpty) 'variant': variantExact,
    };

    try {
      final res = await _api.postMultipart(
        AppConfig.colorVariantImagesUrl(),
        fields: fields,
      );
      final parsed = VariantImagesResponse.fromMap(res);

      return parsed;
    } catch (e) {
      return VariantImagesResponse(success: false, images: const []);
    }
  }

  Future<VariantInfoResponse> fetchVariantInfoAdaptive({
    required int productId,
    required Map<String, String> selectionsByLabel,
    required String changedGroupLabel,
  }) async {
    String keyify(String name) {
      final onlyAscii = name
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\s:_-]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      for (final k in ['color', 'size', 'material']) {
        if (onlyAscii.contains(k)) return k;
      }
      return onlyAscii.replaceAll(' ', '_');
    }

    final byKey = <String, String>{};
    selectionsByLabel.forEach((k, v) => byKey[keyify(k)] = v);
    final changedKey = keyify(changedGroupLabel);

    return fetchVariantInfoByKey(
      productId: productId,
      selectionsByKey: byKey,
      changedBackendKey: changedKey,
    );
  }

  Future<VariantImagesResponse> fetchVariantImages({
    required int productId,
    required Map<String, String> selectionsByLabel,
  }) async {
    String keyify(String name) {
      final onlyAscii = name
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\s:_-]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      for (final k in ['color', 'size', 'material']) {
        if (onlyAscii.contains(k)) return k;
      }
      return onlyAscii.replaceAll(' ', '_');
    }

    final byKey = <String, String>{};
    selectionsByLabel.forEach((k, v) => byKey[keyify(k)] = v);

    return fetchVariantImagesByKey(
      productId: productId,
      selectionsByKey: byKey,
    );
  }
}
