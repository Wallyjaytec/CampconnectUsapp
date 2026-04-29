import '../../../core/config/app_config.dart';

class ColorVariantImage {
  final String regular;
  final String? zoom;
  final String? type;
  ColorVariantImage({required this.regular, this.zoom, this.type});

  factory ColorVariantImage.fromJson(Map<String, dynamic> j) {
    final reg = AppConfig.assetUrl(j['regular']?.toString() ?? '');
    final zoom = AppConfig.assetUrl(j['zoom']?.toString() ?? '');
    return ColorVariantImage(
      regular: reg,
      zoom: zoom.isEmpty ? null : zoom,
      type: j['type']?.toString(),
    );
  }
}

class ColorVariantImagesModel {
  final bool success;
  final List<ColorVariantImage> images;
  ColorVariantImagesModel({required this.success, required this.images});

  factory ColorVariantImagesModel.fromJson(Map<String, dynamic> j) {
    final imgs = <ColorVariantImage>[];
    if (j['images'] is List) {
      for (final e in (j['images'] as List)) {
        if (e is Map<String, dynamic>) {
          imgs.add(ColorVariantImage.fromJson(e));
        }
      }
    }
    final ok = (j['success'] == true) || (j['success']?.toString() == 'true');
    return ColorVariantImagesModel(success: ok, images: imgs);
  }
}
